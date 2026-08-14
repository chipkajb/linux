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

return M
