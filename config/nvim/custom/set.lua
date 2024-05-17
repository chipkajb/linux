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

--- column width
vim.opt.colorcolumn = "88"

--- leader key
vim.g.mapleader = " "

--- relative line numbering
vim.opt.relativenumber = true
