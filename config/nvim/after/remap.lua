--- remove search highlight
vim.keymap.set("n", "//", ":nohl<CR>", {desc="Remove search highlights"})

--- split buffer
vim.keymap.set("n", "<leader>v", ":vnew<CR>", {silent=true, desc="Split buffer vertically"})
vim.keymap.set("n", "<leader>h", ":new<CR>", {silent=true, desc="Split buffer horizontally"})
