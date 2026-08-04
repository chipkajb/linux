-- override nvchad telescope find/grep with fff (resident index)
vim.keymap.set("n", "<leader>ff", function()
  require("fff").find_files()
end, { desc = "FFF find files" })

vim.keymap.set("n", "<leader>fw", function()
  require("fff").live_grep()
end, { desc = "FFF live grep" })

vim.keymap.set("n", "<leader>fz", function()
  require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
end, { desc = "FFF fuzzy live grep" })

vim.keymap.set({ "n", "x" }, "<leader>fW", function()
  require("fff").live_grep_under_cursor()
end, { desc = "FFF grep word/selection" })
