--- line numbering
vim.opt.nu = true
vim.opt.relativenumber = true

--- mouse use
vim.opt.mouse = 'a'

--- tabs
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.breakindent = true

--- line wrap
vim.opt.wrap = false

--- store undo history locally
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

--- search word highlighting, case sensitivity
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

--- colors
vim.opt.termguicolors = true

--- scrolling
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

--- fast updates
vim.opt.updatetime = 50

--- soft wrap only: textwidth 0 avoids inserting hard line breaks when typing (paste stays one logical line)
--- use colorcolumn as a visual guide without forcing newlines in the buffer
vim.opt.textwidth = 0
vim.opt.colorcolumn = "120"

--- leader key
vim.g.mapleader = " "

--- yank / put use the system clipboard (+) so you can paste in other apps
vim.opt.clipboard = "unnamedplus"
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    vim.opt.clipboard = "unnamedplus"
  end,
})

--- relative line numbering
vim.opt.relativenumber = true
