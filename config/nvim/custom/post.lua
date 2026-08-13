-- vim-markdown folds entire sections by default ("+-- N lines"); render-markdown handles display
vim.g.vim_markdown_folding_disabled = 1

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

-- Neovim 0.12: start built-in treesitter when a parser exists for the buffer filetype
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    local lang = vim.bo[ev.buf].filetype
    if lang ~= "" and vim.treesitter.language.get_lang(lang) then
      pcall(vim.treesitter.start, ev.buf)
    end
  end,
})

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

-- Quick markdown commands
vim.keymap.set("n", "<leader>1", "I# <Esc>", { desc = "H1 header" })
vim.keymap.set("n", "<leader>2", "I## <Esc>", { desc = "H2 header" })
vim.keymap.set("n", "<leader>3", "I### <Esc>", { desc = "H3 header" })
