-- override nvchad telescope find/grep with fff (resident index)
vim.keymap.set("n", "<leader>ff", function()
  require("fff").find_files()
end, { desc = "Find: files" })

vim.keymap.set("n", "<leader>fg", function()
  require("fff").live_grep()
end, { desc = "Find: grep (live, project-wide)" })

vim.keymap.set("n", "<leader>fz", function()
  require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
end, { desc = "Find: grep, fuzzy" })

vim.keymap.set({ "n", "x" }, "<leader>fw", function()
  require("fff").live_grep_under_cursor()
end, { desc = "Find: word/selection under cursor" })
