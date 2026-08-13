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

-- NvChad theme (base46 cache written during lazy setup)
vim.schedule(function()
  local defaults = vim.g.base46_cache .. "defaults"
  if vim.fn.filereadable(defaults) == 1 then
    dofile(defaults)
    dofile(vim.g.base46_cache .. "statusline")
  end
end)

require("custom.post")
