require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<Tab>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = {},
  color = {
    suggestion_color = "#808080",
    cterm = 244,
  },
  disable_inline_completion = false,
  disable_keymaps = false,
})

vim.keymap.set("n", "<leader>cs", function()
  require("supermaven-nvim.api").toggle()
end, { desc = "Toggle Supermaven suggestions" })
