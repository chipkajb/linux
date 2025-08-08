require("custom.remap")
require("custom.set")
require("custom.plugins")
require("custom.chadrc")

-- Delayed loading of Lua file
vim.defer_fn(function()
    local path1 = vim.fn.stdpath('config') .. '/after/plugin/tmux_navigator.lua'
    dofile(path1)
    local path2 = vim.fn.stdpath('config') .. '/after/remap.lua'
    dofile(path2)
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
vim.cmd('syntax on')
vim.cmd('filetype plugin indent on')

-- Default to markdown for new/unnamed buffers
vim.api.nvim_create_autocmd({"BufNewFile", "BufEnter"}, {
  pattern = "*",
  callback = function()
    local filename = vim.fn.expand('%:t')
    local extension = vim.fn.expand('%:e')
    
    if (filename == '' or extension == '') and 
       vim.bo.buftype == '' and 
       vim.bo.filetype == '' then
      vim.bo.filetype = 'markdown'
    end
  end,
})

-- Markdown-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 1  -- Partial syntax hiding
    vim.opt_local.spell = true      -- Enable spellcheck
    vim.opt_local.textwidth = 80    -- Line wrapping for prose
    vim.opt_local.colorcolumn = ""  -- Remove distracting color column for writing
    
    -- Optional: Set a different background for better writing experience
    vim.cmd([[
      highlight Normal guibg=#1e1e1e
      highlight ColorColumn NONE
    ]])
  end,
})

-- Set subtle color column for non-markdown files
vim.opt.colorcolumn = "80"
vim.cmd([[
  highlight ColorColumn guibg=#2d2d2d ctermbg=236
]])

-- Quick markdown commands
vim.keymap.set('n', '<leader>1', 'I# <Esc>', { desc = 'H1 header' })
vim.keymap.set('n', '<leader>2', 'I## <Esc>', { desc = 'H2 header' })
vim.keymap.set('n', '<leader>3', 'I### <Esc>', { desc = 'H3 header' })