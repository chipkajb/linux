require("custom.remap")
require("custom.set")

-- Delayed loading of Lua file
vim.defer_fn(function()
    local path1 = vim.fn.stdpath('config') .. '/after/plugin/tmux_navigator.lua'
    dofile(path1)
    local path2 = vim.fn.stdpath('config') .. '/after/remap.lua'
    dofile(path2)
end, 0)

