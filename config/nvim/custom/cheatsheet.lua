-- Live keymap cheat sheet: grouped, aligned, / searchable
local M = {}

local MODES = { "n", "v", "x", "o", "i", "t", "c" }

-- ordered sections: { id, title, match(item) -> bool }
-- first match wins; undocumented handled separately
local SECTIONS = {
  { id = "help", title = "Help" },
  { id = "find", title = "Find" },
  { id = "harpoon", title = "Harpoon" },
  { id = "files", title = "Files & buffers" },
  { id = "lsp", title = "LSP" },
  { id = "debug", title = "Debug" },
  { id = "git", title = "Git" },
  { id = "edit", title = "Edit" },
  { id = "markdown", title = "Markdown" },
  { id = "window", title = "Windows & tmux" },
  { id = "terminal", title = "Terminal" },
  { id = "other", title = "Other" },
  { id = "undoc", title = "Undocumented" },
}

local function pretty_lhs(lhs)
  if not lhs then
    return ""
  end
  local leader = vim.g.mapleader or "\\"
  if leader == " " then
    lhs = lhs:gsub("^ ", "<leader>")
    lhs = lhs:gsub("<Space>", "<leader>")
  elseif leader ~= "" then
    lhs = lhs:gsub("^" .. vim.pesc(leader), "<leader>")
  end
  return lhs
end

local function clean_desc(desc)
  desc = desc:gsub("^%s+", ""):gsub("%s+$", "")
  desc = desc:gsub("^LSP%s+", "")
  desc = desc:gsub("^general%s+", "")
  desc = desc:gsub("^telescope%s+", "")
  desc = desc:gsub("^nvimtree%s+", "")
  desc = desc:gsub("^whichkey%s+", "")
  -- shorten raw rhs dumps
  desc = desc:gsub("^<Cmd>", ""):gsub("<CR>$", ""):gsub("^:", "")
  if #desc > 60 then
    desc = desc:sub(1, 57) .. "..."
  end
  return desc
end

local function section_for(item)
  if item.undocumented then
    return "undoc"
  end
  local lhs, desc, mode = item.lhs:lower(), item.desc:lower(), item.mode

  -- which-key internal triggers → other (not Help)
  if desc:find("which%-key%-trigger") then
    return "other"
  end

  if
    lhs == "<leader>?"
    or lhs == "<leader>ch"
    or desc == "ide cheat sheet"
    or desc == "nvchad cheatsheet"
  then
    return "help"
  end
  if lhs:find("<leader>f", 1, true) or desc:find("fff") or desc:find("find file") or desc:find("live grep") or desc:find("fuzzy") then
    return "find"
  end
  if desc:find("harpoon") or lhs:match("^<leader>[1-4]$") or lhs == "<leader>a" or lhs == "<c-e>" then
    return "harpoon"
  end
  if
    lhs == "-"
    or desc:find("oil")
    or desc:find("nvimtree")
    or desc:find("nvim%-tree")
    or lhs == "<c-n>"
    or lhs == "<leader>e"
    or lhs:find("<leader>b", 1, true)
    or desc:find("buffer")
    or lhs == "<tab>"
    or lhs == "<s-tab>"
    or desc:find("tabufline")
  then
    return "files"
  end
  if
    desc:find("lsp")
    or desc:find("diagnostic")
    or desc:find("trouble")
    or desc:find("hover")
    or desc:find("definition")
    or desc:find("reference")
    or desc:find("rename")
    or desc:find("code action")
    or desc:find("implementation")
    or desc:find("pyright")
    or desc:find("python env")
    or lhs:match("^g[dDrRiI]$")
    or (lhs == "K" or lhs == "k") and desc:find("hover")
    or lhs:find("<leader>ca", 1, true)
    or lhs:find("<leader>ra", 1, true)
    or lhs:find("<leader>pv", 1, true)
    or lhs:find("<leader>x", 1, true)
    or lhs == "[d"
    or lhs == "]d"
  then
    return "lsp"
  end
  if desc:find("git") or desc:find("fugitive") or desc:find("gitsigns") or lhs:find("<leader>g", 1, true) then
    return "git"
  end
  if
    desc:find("dap")
    or desc:find("debug")
    or desc:find("breakpoint")
    or lhs:match("^<f5>$")
    or lhs:match("^<f9>$")
    or lhs:match("^<f1[012]>$")
    or lhs:find("<leader>d", 1, true) and (
      desc:find("dap")
      or desc:find("debug")
      or desc:find("breakpoint")
      or desc:find("step")
      or desc:find("repl")
      or desc:find("terminate")
    )
  then
    return "debug"
  end
  if
    desc:find("markdown")
    or desc:find("render%-markdown")
    or lhs:match("^<leader>m%d")
    or lhs == "<leader>md"
  then
    return "markdown"
  end
  if mode == "t" or desc:find("terminal") then
    return "terminal"
  end
  if
    desc:find("tmux")
    or desc:find("window")
    or desc:find("split")
    or desc:find("resize")
    or lhs == "<leader>v"
    or lhs == "<leader>h"
    or lhs:match("^<c%-[hjkl]>$")
  then
    return "window"
  end
  if
    desc:find("yank")
    or desc:find("paste")
    or desc:find("delete")
    or desc:find("comment")
    or desc:find("surround")
    or desc:find("indent")
    or desc:find("undo")
    or desc:find("replace")
    or desc:find("move text")
    or lhs:find("<leader>y", 1, true)
    or lhs:find("<leader>d", 1, true)
    or lhs == "<leader>s"
    or lhs == "<leader>u"
    or lhs == "<leader>/"
    or (lhs:find("<leader>p", 1, true) and not lhs:find("<leader>pv", 1, true))
  then
    return "edit"
  end
  return "other"
end

local function collect()
  local seen = {}
  local list = {}

  local function add(mode, map)
    local lhs = map.lhs
    if not lhs or lhs == "" then
      return
    end
    if lhs:find("<Plug>", 1, true) or lhs:find("<SNR>", 1, true) then
      return
    end
    local undocumented = not (map.desc and map.desc ~= "")
    local desc
    if not undocumented then
      desc = map.desc
    elseif map.rhs and map.rhs ~= "" then
      desc = map.rhs
    elseif map.callback then
      desc = "<lua>"
    else
      desc = "(no rhs)"
    end
    desc = clean_desc(desc)
    local pretty = pretty_lhs(lhs)
    local key = mode .. "\0" .. pretty:lower() .. "\0" .. desc:lower()
    if seen[key] then
      return
    end
    seen[key] = true
    list[#list + 1] = {
      mode = mode,
      lhs = pretty,
      desc = desc,
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

  local items = {}
  for _, item in ipairs(list) do
    item.section = section_for(item)
    items[#items + 1] = item
  end

  -- merge identical lhs+desc across modes → "n,v"
  local merged = {}
  local index = {}
  for _, item in ipairs(items) do
    local k = item.section .. "\0" .. item.lhs:lower() .. "\0" .. item.desc:lower()
    local existing = index[k]
    if existing then
      if not existing.modes[item.mode] then
        existing.modes[item.mode] = true
        existing.mode_list[#existing.mode_list + 1] = item.mode
      end
    else
      local row = {
        section = item.section,
        lhs = item.lhs,
        desc = item.desc,
        undocumented = item.undocumented,
        modes = { [item.mode] = true },
        mode_list = { item.mode },
      }
      index[k] = row
      merged[#merged + 1] = row
    end
  end

  local mode_order = { n = 1, v = 2, x = 3, o = 4, i = 5, t = 6, c = 7 }
  for _, row in ipairs(merged) do
    table.sort(row.mode_list, function(a, b)
      return (mode_order[a] or 99) < (mode_order[b] or 99)
    end)
    row.mode_str = table.concat(row.mode_list, ",")
  end

  return merged
end

local function section_order(id)
  for i, s in ipairs(SECTIONS) do
    if s.id == id then
      return i
    end
  end
  return 99
end

function M.lines()
  local items = collect()
  table.sort(items, function(a, b)
    local ao, bo = section_order(a.section), section_order(b.section)
    if ao ~= bo then
      return ao < bo
    end
    local a_lead = a.lhs:find("^<leader>") and 0 or 1
    local b_lead = b.lhs:find("^<leader>") and 0 or 1
    if a_lead ~= b_lead then
      return a_lead < b_lead
    end
    if a.lhs:lower() ~= b.lhs:lower() then
      return a.lhs:lower() < b.lhs:lower()
    end
    return a.desc < b.desc
  end)

  -- column widths
  local mode_w, lhs_w = 3, 10
  for _, item in ipairs(items) do
    mode_w = math.max(mode_w, #item.mode_str)
    lhs_w = math.max(lhs_w, #item.lhs)
  end
  mode_w = math.min(mode_w, 8)
  lhs_w = math.min(lhs_w, 28)

  local by_section = {}
  for _, item in ipairs(items) do
    by_section[item.section] = by_section[item.section] or {}
    by_section[item.section][#by_section[item.section] + 1] = item
  end

  local out = {
    " KEYMAPS",
    " / search   n/N next match   q close",
    "",
  }

  -- table of contents
  out[#out + 1] = " CONTENTS"
  for _, sec in ipairs(SECTIONS) do
    local rows = by_section[sec.id]
    if rows and #rows > 0 then
      out[#out + 1] = string.format("   %-22s %3d", sec.title, #rows)
    end
  end
  out[#out + 1] = ""

  local n_doc, n_undoc = 0, 0
  for _, sec in ipairs(SECTIONS) do
    local rows = by_section[sec.id]
    if rows and #rows > 0 then
      out[#out + 1] = ""
      out[#out + 1] = string.format(" %s", sec.title:upper())
      out[#out + 1] = " " .. string.rep("─", mode_w + lhs_w + 36)
      for _, item in ipairs(rows) do
        if item.undocumented then
          n_undoc = n_undoc + 1
        else
          n_doc = n_doc + 1
        end
        out[#out + 1] = string.format(
          " %-" .. mode_w .. "s  %-" .. lhs_w .. "s  %s",
          item.mode_str,
          item.lhs,
          item.desc
        )
      end
    end
  end

  out[#out + 1] = ""
  out[#out + 1] = string.format(" %d maps  ·  %d documented  ·  %d undocumented", #items, n_doc, n_undoc)
  out[#out + 1] = " Builtin vim keys (hjkl, d, c, …) are not listed."
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

  local width = math.min(92, vim.o.columns - 2)
  local height = math.min(math.max(#lines + 1, 16), vim.o.lines - 2)
  local row = math.max(0, math.floor((vim.o.lines - height) / 2))
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " keymaps ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].scrolloff = 1

  -- light syntax for headers / leader keys
  vim.api.nvim_set_hl(0, "CheatSheetHeader", { bold = true, fg = "#d79921" })
  vim.api.nvim_set_hl(0, "CheatSheetLeader", { fg = "#83a598" })
  vim.api.nvim_set_hl(0, "CheatSheetMode", { fg = "#928374" })
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[syntax match CheatSheetHeader /^ [A-Z][A-Z0-9 &]\+$/]])
    vim.cmd([[syntax match CheatSheetHeader /^ CONTENTS$/]])
    vim.cmd([[syntax match CheatSheetHeader /^ KEYMAPS$/]])
    vim.cmd([[syntax match CheatSheetLeader /<leader>[^ ]*/]])
    vim.cmd([[syntax match CheatSheetMode /^ [nvixtoc,]\+/]])
  end)

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

return M
