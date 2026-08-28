vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"

require("custom.set")
require("custom.remap")

-- bootstrap lazy.nvim and NvChad plugins
local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },
}
vim.list_extend(plugins, require("custom.plugins"))

require("lazy").setup(plugins, require("configs.lazy"))

-- NvChad FilePost + friends (gitsigns / lsp lazy events); set ui_entered if UI already up
pcall(function()
  require "nvchad.autocmds"
  if vim.v.vim_did_enter == 1 then
    vim.g.ui_entered = true
  end
end)

-- NvChad theme (base46 cache written during lazy setup)
vim.schedule(function()
  local cache = vim.g.base46_cache
  for _, name in ipairs({ "defaults", "statusline", "syntax", "treesitter", "lsp" }) do
    local path = cache .. name
    if vim.fn.filereadable(path) == 1 then
      dofile(path)
    end
  end
end)

require("custom.post")
