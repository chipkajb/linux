-- Live keymap cheat sheet: all maps with descriptions, grouped, / searchable
local M = {}

local MODES = { "n", "v", "x", "o", "i", "t", "c" }

local GROUP_TITLES = {
  ["?"] = "help",
  a = "harpoon / append",
  b = "buffers",
  c = "code / chad",
  d = "delete / diag",
  e = "explore",
  f = "find",
  g = "git / goto",
  h = "split / help",
  m = "markdown",
  p = "python / paste",
  r = "rename / run",
  s = "search / replace",
  u = "undo",
  v = "vsplit / venv",
  w = "workspace / window",
  x = "trouble / exec",
  y = "yank",
}

local function leader_str()
  local l = vim.g.mapleader
  if l == nil or l == "" then
    return "\\"
  end
  if l == " " then
    return "<leader>"
  end
  return l
end

local function pretty_lhs(lhs)
  if not lhs then
    return ""
  end
  local leader = vim.g.mapleader or "\\"
  if leader == " " then
    lhs = lhs:gsub("^ ", "<leader>")
    lhs = lhs:gsub("<Space>", "<leader>")
  elseif leader ~= "" then
    local esc = vim.pesc(leader)
    lhs = lhs:gsub("^" .. esc, "<leader>")
  end
  return lhs
end

local function group_key(lhs)
  local pretty = pretty_lhs(lhs)
  local after = pretty:match("^<leader>(.)")
  if after then
    return after
  end
  if pretty:match("^g") then
    return "g"
  end
  if pretty:match("^%[") or pretty:match("^%]") then
    return "d"
  end
  return "_"
end

local function collect()
  local seen = {}
  local items = {}

  local function add(mode, map)
    local lhs = map.lhs
    if not lhs or lhs == "" then
      return
    end
    -- skip pure plug / snip internals
    if lhs:find("<Plug>", 1, true) or lhs:find("<SNR>", 1, true) then
      return
    end
    local desc = map.desc
    local undocumented = false
    if not desc or desc == "" then
      undocumented = true
      if map.rhs and map.rhs ~= "" then
        desc = map.rhs
      elseif map.callback then
        desc = "<lua>"
      else
        desc = "(no rhs)"
      end
    end
    local key = mode .. "\0" .. lhs .. "\0" .. desc
    if seen[key] then
      return
    end
    seen[key] = true
    items[#items + 1] = {
      mode = mode,
      lhs = pretty_lhs(lhs),
      desc = desc,
      group = undocumented and "~" or group_key(lhs),
      undocumented = undocumented,
    }
  end

  for _, mode in ipairs(MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      add(mode, map)
    end
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
      add(mode, map)
    end
  end

  table.sort(items, function(a, b)
    -- undocumented (~) last
    if a.group ~= b.group then
      if a.group == "~" then
        return false
      end
      if b.group == "~" then
        return true
      end
      return a.group < b.group
    end
    if a.lhs ~= b.lhs then
      return a.lhs < b.lhs
    end
    return a.mode < b.mode
  end)

  return items
end

function M.lines()
  local items = collect()
  local out = {
    "  KEYMAPS  —  / search   n/N next   q close",
    "  (mapped keys only — builtin vim motions like hjkl are not listed)",
    "",
  }

  local cur = nil
  local n_doc, n_undoc = 0, 0
  for _, item in ipairs(items) do
    if item.undocumented then
      n_undoc = n_undoc + 1
    else
      n_doc = n_doc + 1
    end
    if item.group ~= cur then
      cur = item.group
      local title = GROUP_TITLES[cur] or (cur == "_" and "other" or (cur == "~" and "undocumented (no desc)" or cur))
      out[#out + 1] = ""
      out[#out + 1] = "  " .. string.upper(title)
      out[#out + 1] = "  " .. string.rep("-", 48)
    end
    out[#out + 1] = string.format("  %-4s %-20s  %s", item.mode, item.lhs, item.desc)
  end

  out[#out + 1] = ""
  out[#out + 1] = string.format("  %d keymaps (%d documented, %d undocumented)", #items, n_doc, n_undoc)
  return out
end

function M.open()
  local lines = M.lines()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "cheatsheet"
  vim.bo[buf].swapfile = false

  local width = math.min(88, vim.o.columns - 4)
  local height = math.min(math.max(#lines + 1, 12), vim.o.lines - 4)
  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " keymaps  (/ to search) ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "close" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, desc = "close" })
  -- / works as normal search in this buffer
end

return M
