--- remove search highlight
vim.keymap.set("n", "<leader>n", ":nohl<CR>", {desc="Remove search highlights"})

--- split buffer
vim.keymap.set("n", "<leader>v", ":vsp<CR>", {silent=true, desc="Split buffer vertically"})
vim.keymap.set("n", "<leader>h", ":sp<CR>", {silent=true, desc="Split buffer horizontally"})
