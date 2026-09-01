--- line numbering
vim.opt.nu = true
vim.opt.relativenumber = true

--- mason LSP binaries (NvChad options.lua not loaded by this bootstrap)
do
  local sep = package.config:sub(1, 1)
  local delim = vim.fn.has("win32") == 1 and ";" or ":"
  vim.env.PATH = table.concat({ vim.fn.stdpath("data"), "mason", "bin" }, sep) .. delim .. vim.env.PATH
end

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
vim.cmd("filetype on")
vim.cmd("filetype plugin on")
vim.cmd("filetype indent on")

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

--- yank / put: xclip locally, OSC 52 over SSH (via tmux client_tty when in tmux)
require("custom.clipboard").setup()
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
