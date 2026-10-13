require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<Right>",
    clear_suggestion = "<C-]>",
    accept_word = "<C-Right>",
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
  -- Register keymaps below. The plugin's <Right> map falls back to <Tab>
  -- when no suggestion appears. That inserts indentation instead of moving
  -- the cursor.
  disable_keymaps = true,
})

local preview = require("supermaven-nvim.completion_preview")

-- True only when Supermaven renders text the user can see.
-- Whitespace-only suggestions show as invisible dim text. Accepting one then
-- looks like the cursor inserts spaces at random.
local function has_visible_suggestion()
  local instance = preview:get_inlay_instance()
  return instance ~= nil
    and instance.is_active
    and type(instance.completion_text) == "string"
    and instance.completion_text:match("%S") ~= nil
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

--- Accept the whole suggestion, or move the cursor when nothing appears.
local function accept_suggestion()
  if has_visible_suggestion() then
    preview.on_accept_suggestion()
  else
    feed("<Right>")
  end
end

--- Accept one word of the suggestion, or move a word when nothing appears.
local function accept_word()
  if has_visible_suggestion() then
    preview.on_accept_suggestion_word()
  else
    feed("<C-Right>")
  end
end

vim.keymap.set("i", "<Right>", accept_suggestion, {
  noremap = true,
  silent = true,
  desc = "Accept suggestion / move right",
})
vim.keymap.set("i", "<C-Right>", accept_word, {
  noremap = true,
  silent = true,
  desc = "Accept one suggestion word / move word right",
})
vim.keymap.set("i", "<C-j>", accept_word, {
  noremap = true,
  silent = true,
  desc = "Accept one suggestion word",
})
vim.keymap.set("i", "<C-]>", preview.on_dispose_inlay, {
  noremap = true,
  silent = true,
  desc = "Clear suggestion",
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
