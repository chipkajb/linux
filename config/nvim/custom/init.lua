require("custom.remap")
require("custom.set")

-- Delayed loading of Lua file
vim.defer_fn(function()
    require('after.plugin.tmux_navigator')
end, 0)

