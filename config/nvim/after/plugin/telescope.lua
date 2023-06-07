local builtin = require('telescope.builtin')

--- project files
vim.keymap.set('n','<leader>pf', builtin.find_files, {desc="[P]roject [F]ile search"})

--- git files
vim.keymap.set('n','<C-p>', builtin.git_files, {desc="Search Git files"})

--- project search
vim.keymap.set('n','<leader>ps', function()
  builtin.grep_string({ search = vim.fn.input("Grep > ")})
end, {desc="[P]roject [S]earch (grep string)"})

--- show help
vim.keymap.set('n','<leader>k', builtin.keymaps, {desc="Search [K]eymaps"})

--- show diagnostics
vim.keymap.set('n','<leader>pd', builtin.diagnostics, {desc="[P]roject [D]iagnostics search"})
