require("custom.remap")
require("custom.set")

-- Delayed loading of Lua file
vim.defer_fn(function()
    local path = vim.fn.stdpath('config') .. '/after/plugin/tmux_navigator.lua'
    dofile(path)
end, 0)

