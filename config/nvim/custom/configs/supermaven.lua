require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<Right>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-j>",
  },
  ignore_filetypes = {
    fff_input = true,
    fff_list = true,
    fff_preview = true,
  },
  color = {
    suggestion_color = "#808080",
    cterm = 244,
  },
  disable_inline_completion = false,
  disable_keymaps = false,
})

-- Pro activation popup uses nvim_open_win(..., enter=true) and steals focus
-- from the first InsertEnter (often <leader>ff). Auto-pick free tier instead.
do
  local binary = require("supermaven-nvim.binary.binary_handler")
  function binary:open_popup(_message, _include_free)
    self:use_free_version()
  end
end

vim.keymap.set("n", "<leader>cs", function()
  require("supermaven-nvim.api").toggle()
end, { desc = "Toggle Supermaven suggestions" })
