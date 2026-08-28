-- vim-markdown folds entire sections by default ("+-- N lines"); render-markdown handles display
vim.g.vim_markdown_folding_disabled = 1

-- ASCII-only UI glyphs (no nerd font). Re-apply after plugins finish loading
-- because NvChad lsp defaults() and tabufline overwrite with nerd glyphs.
local noicons = require("custom.configs.noicons")
noicons.apply()
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    noicons.apply()
  end,
})
-- lspconfig loads on BufRead — re-apply diagnostics after it
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("NoIconsLsp", { clear = true }),
  once = true,
  callback = function()
    noicons.diagnostic_signs()
  end,
})

-- Delayed loading of after/ plugin scripts
vim.defer_fn(function()
  local path1 = vim.fn.stdpath("config") .. "/after/plugin/tmux_navigator.lua"
  dofile(path1)
  local path2 = vim.fn.stdpath("config") .. "/after/remap.lua"
  dofile(path2)
  local path3 = vim.fn.stdpath("config") .. "/after/plugin/fff.lua"
  if vim.fn.filereadable(path3) == 1 then
    dofile(path3)
  end
  pcall(require, "custom.configs.whichkey")
end, 0)

-- Basic vim settings
vim.opt.number = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Disable the distracting red color column
vim.opt.colorcolumn = ""

-- Enable syntax highlighting
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

-- Default to markdown for note-taking: unnamed buffers, extensionless paths,
-- and buffers vim would treat as plain text (so `nvim` alone gets markdown).
local default_md = vim.api.nvim_create_augroup("CustomDefaultMarkdown", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufNewFile" }, {
  group = default_md,
  pattern = "*",
  callback = function(ev)
    local buf = ev.buf
    if vim.bo[buf].buftype ~= "" then
      return
    end
    local path = vim.api.nvim_buf_get_name(buf)
    local ext = path ~= "" and vim.fn.fnamemodify(path, ":e") or ""
    if path ~= "" and ext ~= "" then
      return
    end
    local ft = vim.bo[buf].filetype
    if ft == "" or ft == "text" then
      vim.bo[buf].filetype = "markdown"
    end
  end,
})

-- Treesitter highlight (rtp "syntax" is disabled by lazy config — no fallback colors).
-- FFF preview uses its own highlighter; the real buffer needs vim.treesitter.start.
local function ensure_filetype(buf)
  local ft = vim.bo[buf].filetype
  if ft ~= "" then
    return ft
  end
  local name = vim.api.nvim_buf_get_name(buf)
  local matched = vim.filetype.match({ buf = buf }) or (name ~= "" and vim.filetype.match({ filename = name })) or ""
  if matched and matched ~= "" then
    -- set without firing FileType recursion storms; we call ensure_treesitter after
    pcall(vim.api.nvim_buf_set_option, buf, "filetype", matched)
    return matched
  end
  return ""
end

local function ensure_treesitter(buf, force)
  buf = buf or 0
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(buf) then
    return false, "invalid buffer"
  end
  if vim.bo[buf].buftype ~= "" then
    return false, "special buftype"
  end
  local ft = ensure_filetype(buf)
  if ft == "" then
    return false, "no filetype"
  end
  local lang = vim.treesitter.language.get_lang(ft) or ft
  pcall(vim.treesitter.language.add, lang)

  if force and vim.treesitter.highlighter.active[buf] then
    pcall(vim.treesitter.stop, buf)
  end
  if not force and vim.treesitter.highlighter.active[buf] then
    return true, "already on"
  end

  -- pcall ok only means no Lua error; start() itself returns false if parser missing
  local pok, started = pcall(vim.treesitter.start, buf, lang)
  if not pok then
    return false, tostring(started)
  end
  if started == false then
    return false, "no parser for " .. lang
  end
  if not vim.treesitter.highlighter.active[buf] then
    -- deferred retry (parser install race)
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) and not vim.treesitter.highlighter.active[buf] then
        pcall(vim.treesitter.language.add, lang)
        pcall(vim.treesitter.start, buf, lang)
      end
    end, 200)
    return false, "highlighter not active for " .. lang
  end
  return true, lang
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWinEnter", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("CustomTreesitterHighlight", { clear = true }),
  callback = function(ev)
    ensure_treesitter(ev.buf, false)
  end,
})

-- If LSP attach left the buffer without TS highlight, start it (don't stop a working one)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("CustomTreesitterAfterLsp", { clear = true }),
  callback = function(ev)
    vim.schedule(function()
      if not vim.treesitter.highlighter.active[ev.buf] then
        ensure_treesitter(ev.buf, false)
      end
    end)
  end,
})

vim.api.nvim_create_user_command("TSStart", function()
  local ok, msg = ensure_treesitter(0, true)
  local buf = vim.api.nvim_get_current_buf()
  local on = vim.treesitter.highlighter.active[buf] ~= nil
  if on then
    vim.notify("treesitter highlight: ON (" .. tostring(msg) .. ")", vim.log.levels.INFO)
  else
    vim.notify("treesitter highlight: FAILED — " .. tostring(msg), vim.log.levels.WARN)
  end
end, { desc = "Start treesitter highlight for current buffer" })

-- Markdown-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldenable = false
    vim.opt_local.foldlevel = 99
    vim.opt_local.conceallevel = 2 -- render-markdown needs conceal for styled headings/links
    vim.opt_local.spell = true -- Enable spellcheck
    vim.opt_local.textwidth = 0 -- No hard wraps; display wraps via wrap/linebreak (clean copy/paste)
    vim.opt_local.colorcolumn = "" -- Remove distracting color column for writing

    vim.cmd([[
      highlight Normal guibg=#1e1e1e
      highlight ColorColumn NONE
    ]])
  end,
})

-- Set subtle color column for non-markdown files
vim.opt.colorcolumn = "120"
vim.cmd([[
  highlight ColorColumn guibg=#2d2d2d ctermbg=236
]])

-- Quick markdown commands (<leader>1-4 = harpoon)
vim.keymap.set("n", "<leader>m1", "I# <Esc>", { desc = "H1 header" })
vim.keymap.set("n", "<leader>m2", "I## <Esc>", { desc = "H2 header" })
vim.keymap.set("n", "<leader>m3", "I### <Esc>", { desc = "H3 header" })
