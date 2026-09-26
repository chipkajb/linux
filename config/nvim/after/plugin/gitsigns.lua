-- gitsigns stage/revert keymaps (NvChad ships signs only, no mappings).
-- require() is lazy so gitsigns (event = User FilePost) is not force-loaded at startup.

local function gs()
    return require("gitsigns")
end

local function sel_range()
    local a, b = vim.fn.line("."), vim.fn.line("v")
    return { math.min(a, b), math.max(a, b) }
end

-- navigate hunks
vim.keymap.set("n", "]c", function()
    gs().nav_hunk("next")
end, { desc = "Git: next hunk" })
vim.keymap.set("n", "[c", function()
    gs().nav_hunk("prev")
end, { desc = "Git: prev hunk" })

-- stage / reset whole hunk at cursor
vim.keymap.set("n", "<leader>ga", function()
    gs().stage_hunk()
end, { desc = "Git: stage hunk" })
vim.keymap.set("n", "<leader>gr", function()
    gs().reset_hunk()
end, { desc = "Git: reset hunk" })
vim.keymap.set("n", "<leader>gU", function()
    gs().undo_stage_hunk()
end, { desc = "Git: undo staged hunk" })

-- stage / reset only the selected lines (partial hunk)
vim.keymap.set("x", "<leader>ga", function()
    gs().stage_hunk(sel_range())
end, { desc = "Git: stage selected lines" })
vim.keymap.set("x", "<leader>gr", function()
    gs().reset_hunk(sel_range())
end, { desc = "Git: reset selected lines" })

-- whole buffer
vim.keymap.set("n", "<leader>gA", function()
    gs().stage_buffer()
end, { desc = "Git: stage buffer" })
vim.keymap.set("n", "<leader>gR", function()
    gs().reset_buffer()
end, { desc = "Git: reset buffer" })

-- inspect
vim.keymap.set("n", "<leader>gp", function()
    gs().preview_hunk()
end, { desc = "Git: preview hunk" })
vim.keymap.set("n", "<leader>gb", function()
    gs().blame_line({ full = true })
end, { desc = "Git: blame line" })
vim.keymap.set("n", "<leader>gB", function()
    gs().toggle_current_line_blame()
end, { desc = "Git: toggle line blame" })
vim.keymap.set("n", "<leader>gD", function()
    gs().diffthis()
end, { desc = "Git: diffthis" })
