---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "gruvchad",
}

M.ui = {
  cmp = {
    icons = false,
  },
  statusline = require("custom.configs.statusline"),
}

-- mason v2 ignores opts.ensure_installed; NvChad reads these via :MasonInstallAll
M.mason = {
  pkgs = {
    "black",
    "pyright",
    "ruff",
    "debugpy",
    "lua-language-server",
    "bash-language-server",
    "json-lsp",
    "yaml-language-server",
    "marksman",
    "typescript-language-server",
    "rust-analyzer",
    "gopls",
  },
}

return M
