--- move chunks of text
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {desc="Move text chunk down"})
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", {desc="Move text chunk up"})

--- keep cursor still
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

--- delete to empty clipboard and paste
vim.keymap.set("x", "<leader>p", "\"_dp", {desc="Delete to empty clipboard, paste"})

--- yank to system clipboard
vim.keymap.set("n", "<leader>y", "\"+y", {desc='Yank to system clipboard'})
vim.keymap.set("v", "<leader>y", "\"+y", {desc='Yank to system clipboard'})
vim.keymap.set("n", "<leader>Y", "\"+Y", {desc='Yank to system clipboard'})

--- delete to system clipboard
vim.keymap.set("n", "<leader>d", "\"_d", {desc='Delete to system clipboard'})
vim.keymap.set("v", "<leader>d", "\"_d", {desc='Delete to system clipboard'})

--- make ctrl-c and esc the same
vim.keymap.set("i", "<C-c>", "<Esc>")

--- ignore Q
vim.keymap.set("n", "Q", "<nop>")

--- change all instances of a word in a file
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {desc="Change all instances of word in file"})

--- run "chmod +x <file>" from inside file
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true }, {desc="chmod +x"})

--- close buffer
vim.keymap.set("n", "<C-w>", function() require("nvchad_ui.tabufline").close_buffer() end, {desc="Close buffer"})

--- remove search highlight
vim.keymap.set("n", "<leader>n", ":nohl<CR>", {desc="Remove search highlights"})

--- source file
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end, {desc="Source file"})

--- adjust window sizes
vim.keymap.set("n", "<C-Up>", ":resize -2<CR>", {desc="Adjust window size up"})
vim.keymap.set("n", "<C-Down>", ":resize +2<CR>", {desc="Adjust window size down"})
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", {desc="Adjust window size left"})
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", {desc="Adjust window size right"})
vim.keymap.set("t", "<C-Up>", "<cmd>resize -2<CR>", {desc="Adjust window size up"})
vim.keymap.set("t", "<C-Down>", "<cmd>resize +2<CR>", {desc="Adjust window size down"})
vim.keymap.set("t", "<C-Left>", "<cmd>vertical resize -2<CR>", {desc="Adjust window size left"})
vim.keymap.set("t", "<C-Right>", "<cmd>vertical resize +2<CR>", {desc="Adjust window size right"})

--- keep highlighted text on indent
vim.keymap.set("v", "<", "<gv", {desc="Indent left"})
vim.keymap.set("v", ">", ">gv", {desc="Indent right"})

--- tmux navigation
vim.keymap.set("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>", {desc="Window left"})
vim.keymap.set("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>", {desc="Window right"})
vim.keymap.set("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>", {desc="Window down"})
vim.keymap.set("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>", {desc="Window up"})
