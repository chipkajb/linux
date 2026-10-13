-- Markdown list editing.
--
--   <CR>      continue the current list item; on an empty item, drop the
--             marker and stay on the line
--   <Tab>     indent the list item (normal mode: fall back to next buffer)
--   <S-Tab>   dedent the list item (normal mode: fall back to prev buffer)
--
-- Visual <Tab>/<S-Tab> indent/dedent the selection.
local M = {}

local function shiftwidth()
  local n = vim.fn.shiftwidth()
  if n == 0 then
    n = vim.fn.tabstop()
  end
  return n > 0 and n or 2
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

local function line_at(lnum)
  return vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
end

local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

--- Describe the list item at the start of `line`, or return nil.
--- Fields: indent, marker, ordered, number, box, rest (content after marker).
local function parse_list_item(line)
  local indent, num, punct, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
  if indent then
    return { indent = indent, marker = num .. punct, ordered = true, number = tonumber(num), rest = rest }
  end

  local bullet
  indent, bullet, rest = line:match("^(%s*)([-*+])%s+(.*)$")
  if not indent then
    return nil
  end

  local item = { indent = indent, marker = bullet, ordered = false, rest = rest }
  local box, after = rest:match("^(%[[ xX]%])%s*(.*)$")
  if box then
    item.box = box
    item.rest = after
  end
  return item
end

local function prev_nonblank(lnum)
  local i = lnum - 1
  while i >= 1 do
    if not is_blank(line_at(i)) then
      return i
    end
    i = i - 1
  end
  return nil
end

local function insert_below(lnum, text)
  vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { text })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #text })
end

--- Insert-mode <CR> handler.
local function on_enter()
  -- Let nvim-cmp confirm the selected item before touching the list.
  if vim.fn.pumvisible() == 1 then
    local ok, cmp = pcall(require, "cmp")
    if ok then
      cmp.confirm({ select = true })
    else
      feed("<C-y>")
    end
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local item = parse_list_item(line)

  if item then
    if is_blank(item.rest) then
      -- Empty item: remove the marker and stay on the line.
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { "" })
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return
    end

    local marker
    if item.ordered then
      marker = tostring(item.number + 1) .. item.marker:sub(-1)
    else
      marker = item.marker
    end
    local prefix = item.indent .. marker .. " "
    if item.box then
      prefix = prefix .. "[ ] "
    end

    local col = vim.api.nvim_win_get_cursor(0)[2]
    local content_start = #item.indent + #item.marker + 1
    if col > content_start and col < #line then
      -- Split mid-item: keep the left half, continue with the right half.
      vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {
        line:sub(1, col),
        prefix .. line:sub(col + 1),
      })
      vim.api.nvim_win_set_cursor(0, { lnum + 1, #prefix })
    else
      insert_below(lnum, prefix)
    end
    return
  end

  -- Blank line after a list: add a flush-left line, not a list-indented one.
  if is_blank(line) then
    local prev = prev_nonblank(lnum)
    if prev and parse_list_item(line_at(prev)) then
      insert_below(lnum, "")
      return
    end
  end

  feed("<CR>")
end

local function dedent(line)
  local indent = line:match("^%s*")
  if indent:sub(1, 1) == "\t" then
    return line:sub(2)
  end
  local spaces = indent:match("^ *") or ""
  return line:sub(math.min(#spaces, shiftwidth()) + 1)
end

--- Shift the list item on the cursor line. Return false when the line is not
--- a list item. Callers can then use their default behavior.
local function shift_list_item(dir)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  if not parse_list_item(line) then
    return false
  end

  local new = dir > 0 and (string.rep(" ", shiftwidth()) .. line) or dedent(line)
  if new ~= line then
    local col = vim.api.nvim_win_get_cursor(0)[2]
    vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new })
    vim.api.nvim_win_set_cursor(0, { lnum, math.max(0, col + #new - #line) })
  end
  return true
end

--- Insert a real tab, or its space expansion, at the cursor.
--- Feedkeys cannot insert text from an insert-mode mapping, so insert directly.
local function insert_literal_tab()
  if vim.bo.expandtab then
    local col = vim.fn.col(".") - 1
    local ts = vim.bo.softtabstop
    if ts == 0 then
      ts = vim.bo.tabstop
    end
    if ts == 0 then
      ts = 4
    end
    vim.api.nvim_put({ string.rep(" ", ts - (col % ts)) }, "c", false, true)
  else
    vim.api.nvim_put({ "\t" }, "c", false, true)
  end
end

--- Insert-mode <Tab>/<S-Tab>. Order: cmp menu, snippet jump, list indent,
--- then a literal tab.
local function insert_tab(dir)
  if vim.fn.pumvisible() == 1 then
    local cmp = require("cmp")
    if dir > 0 then
      cmp.select_next_item()
    else
      cmp.select_prev_item()
    end
    return
  end
  local ok, ls = pcall(require, "luasnip")
  if ok then
    if dir > 0 and ls.expand_or_jumpable() then
      ls.expand_or_jump()
      return
    end
    if dir < 0 and ls.jumpable(-1) then
      ls.jump(-1)
      return
    end
  end
  if shift_list_item(dir) then
    return
  end
  insert_literal_tab()
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CustomMarkdownLists", { clear = true }),
    pattern = "markdown",
    callback = function()
      vim.keymap.set("i", "<CR>", on_enter, { buffer = true, silent = true, desc = "List: continue item" })
      vim.keymap.set("i", "<Tab>", function()
        insert_tab(1)
      end, { buffer = true, silent = true, desc = "List: indent item" })
      vim.keymap.set("i", "<S-Tab>", function()
        insert_tab(-1)
      end, { buffer = true, silent = true, desc = "List: dedent item" })
      vim.keymap.set("n", "<Tab>", function()
        if not shift_list_item(1) then
          require("nvchad.tabufline").next()
        end
      end, { buffer = true, silent = true, desc = "List: indent item" })
      vim.keymap.set("n", "<S-Tab>", function()
        if not shift_list_item(-1) then
          require("nvchad.tabufline").prev()
        end
      end, { buffer = true, silent = true, desc = "List: dedent item" })
      vim.keymap.set("v", "<Tab>", ">gv", { buffer = true, silent = true, desc = "Indent selection" })
      vim.keymap.set("v", "<S-Tab>", "<gv", { buffer = true, silent = true, desc = "Dedent selection" })
    end,
  })
end

return M
