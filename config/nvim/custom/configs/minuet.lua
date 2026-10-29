-- Inline ghost-text completion through minuet-ai.nvim, pointed at Fireworks.
--
-- Accept keys, matching the layout this config used for Supermaven:
--   <Right>      accept the whole suggestion, else move the cursor right
--   <C-Right>    accept one word, else move one word right
--   <C-]>        dismiss the suggestion
--   <leader>cs   toggle automatic suggestions
--
-- minuet's own accept is line-granular, so <C-Right> is implemented here. It
-- works because minuet keeps a suggestion alive while the buffer stays a prefix
-- of it (virtualtext.update_suggestion_on_typing): inserting the next chunk
-- ourselves makes minuet trim the ghost text instead of discarding it.

local ai = require "custom.configs.ai"

if not vim.env[ai.api_key_env] or vim.env[ai.api_key_env] == "" then
  vim.notify(("minuet is the active backend but %s is unset"):format(ai.api_key_env), vim.log.levels.ERROR)
end

--- Ghost text currently rendered by minuet, or nil.
--- Reads minuet's extmark rather than its internal context table, which is
--- module-local. Line 1 lives in virt_text, the rest in virt_lines.
local function ghost_text()
  local ns = require("minuet.virtualtext").ns_id
  local ok, marks = pcall(vim.api.nvim_buf_get_extmarks, 0, ns, { 0, 0 }, -1, { details = true })
  if not ok then
    return nil
  end

  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details and details.virt_text then
      local lines = { details.virt_text[1][1] }
      for _, virt_line in ipairs(details.virt_lines or {}) do
        lines[#lines + 1] = virt_line[1][1]
      end
      -- minuet appends a "(1/3)" choice annotation to the last line
      lines[#lines] = (lines[#lines]:gsub("%s*%(%d+/%d+%)$", ""))
      return table.concat(lines, "\n")
    end
  end

  return nil
end

--- Next accept-chunk of `text`: optional leading newline, indentation, one word.
--- Falls back to one non-space run so punctuation and brackets move too.
local function next_chunk(text)
  local newline, indent, word = text:match "^(%c?)([ \t]*)([%w_]+)"
  if word then
    return newline .. indent .. word
  end
  local nl, ind, run = text:match "^(%c?)([ \t]*)(%S+)"
  if run then
    return nl .. ind .. run
  end
  return nil
end

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

local function visible()
  return require("minuet.virtualtext").action.is_visible()
end

--- Accept the whole suggestion, or move the cursor when nothing is shown.
local function accept_all()
  if visible() then
    require("minuet.virtualtext").action.accept()
  else
    feed "<Right>"
  end
end

--- Accept one word, or move one word when nothing is shown.
---
--- minuet does not notice a programmatic insert: it trims its suggestion on
--- CursorMovedI, which an API edit does not reliably fire. The ghost text is
--- therefore still the full suggestion after the first chunk lands, and a second
--- press would insert the first chunk again. `state` tracks how much of the
--- current ghost text has already been written, and resets whenever the ghost or
--- the line changes under us.
local state = { ghost = nil, consumed = 0, line = nil }

local function accept_word()
  if not visible() then
    feed "<C-Right>"
    return
  end

  local ghost = ghost_text()
  if not ghost or ghost == "" then
    feed "<C-Right>"
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local line, col = cursor[1], cursor[2]
  local current_line = vim.api.nvim_get_current_line()

  if state.ghost ~= ghost or state.line ~= current_line then
    state = { ghost = ghost, consumed = 0, line = current_line }
  end

  local chunk = next_chunk(ghost:sub(state.consumed + 1))
  if not chunk or chunk == "" then
    feed "<C-Right>"
    return
  end

  local parts = vim.split(chunk, "\n", { plain = true })
  vim.api.nvim_buf_set_text(0, line - 1, col, line - 1, col, parts)
  if #parts == 1 then
    vim.api.nvim_win_set_cursor(0, { line, col + #chunk })
  else
    vim.api.nvim_win_set_cursor(0, { line + #parts - 1, #parts[#parts] })
  end

  state.consumed = state.consumed + #chunk
  state.line = vim.api.nvim_get_current_line()
end

require("minuet").setup {
  provider = "openai_fim_compatible",
  -- one request per trigger; minuet's default of 3 triples the cost
  n_completions = 1,
  context_window = 6000,
  context_ratio = 0.75,
  throttle = 500,
  debounce = 250,
  request_timeout = 3,
  notify = "warn",
  virtualtext = {
    auto_trigger_ft = {
      "python",
      "lua",
      "go",
      "rust",
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
      "c",
      "cpp",
      "bash",
      "sh",
      "zsh",
      "yaml",
      "toml",
      "json",
      "markdown",
      "gitcommit",
    },
    -- Minuet hides its ghost text while the cmp menu is open. NvChad's cmp
    -- offers buffer and path matches on most keystrokes, so leaving this false
    -- hides the ghost text almost always. Supermaven drew over the menu, and
    -- this matches that behaviour.
    show_on_completion_menu = true,
    -- keymaps are set below, so they can fall through when nothing is shown
    keymap = {},
  },
  provider_options = {
    openai_fim_compatible = {
      -- minuet wants the variable name, not the value
      api_key = ai.api_key_env,
      end_point = ai.endpoint .. "/completions",
      model = ai.model,
      name = "Fireworks",
      stream = true,
      optional = {
        -- Measured: at 256 tokens this model writes the rest of the file. A
        -- blank line is the natural end of a code block, so stop there and cap
        -- the length as a backstop.
        max_tokens = 96,
        stop = { "\n\n" },
        temperature = 0.1,
        top_p = 0.9,
        -- deepseek-v4p1-flash is a reasoning model. Left on, it spends the
        -- token budget on chain-of-thought and returns nothing. Verified
        -- accepted on Fireworks /v1/completions.
        thinking = { type = "disabled" },
      },
    },
  },
}

vim.keymap.set("i", "<Right>", accept_all, { noremap = true, silent = true, desc = "Accept suggestion / move right" })
vim.keymap.set("i", "<C-Right>", accept_word, { noremap = true, silent = true, desc = "Accept one suggestion word / move word right" })
vim.keymap.set("i", "<C-j>", accept_word, { noremap = true, silent = true, desc = "Accept one suggestion word" })
vim.keymap.set("i", "<C-]>", function()
  require("minuet.virtualtext").action.dismiss()
end, { noremap = true, silent = true, desc = "Dismiss suggestion" })

vim.keymap.set("n", "<leader>cs", function()
  require("minuet.virtualtext").action.toggle_auto_trigger()
end, { desc = "Toggle AI suggestions" })

-- minuet arms its auto-trigger from a FileType autocmd registered in its own
-- setup(). A buffer whose FileType already fired never sees that autocmd, so
-- vim.b.minuet_virtual_text_auto_trigger stays nil and should_auto_trigger() is
-- false — no ghost text, no error, nothing to notice. Eager loading covers new
-- buffers; this covers the one already open, and re-checks on every BufEnter.
local function arm_auto_trigger(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local cfg = require("minuet").config.virtualtext
  local ft = vim.bo[bufnr].filetype
  if ft == "" or vim.tbl_contains(cfg.auto_trigger_ignore_ft, ft) then
    return
  end
  if vim.tbl_contains(cfg.auto_trigger_ft, ft) then
    vim.b[bufnr].minuet_virtual_text_auto_trigger = true
  end
end

arm_auto_trigger()
vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function(ev)
    arm_auto_trigger(ev.buf)
  end,
  desc = "[custom.minuet] arm virtual text auto trigger",
})

--- Report why ghost text is or is not appearing. Bound to <leader>ci.
local function diagnose()
  local minuet = require "minuet"
  local cfg = minuet.config
  local ft = vim.bo.filetype
  local key = vim.env[ai.api_key_env]
  local lines = {
    "backend:       " .. ai.backend,
    "model:         " .. ai.model,
    "api key set:   " .. tostring(key ~= nil and key ~= ""),
    "filetype:      " .. (ft ~= "" and ft or "(none)"),
    "ft in list:    " .. tostring(vim.tbl_contains(cfg.virtualtext.auto_trigger_ft, ft)),
    "armed:         " .. tostring(vim.b.minuet_virtual_text_auto_trigger),
    "menu visible:  " .. tostring(require("minuet.utils").completion_menu_visible()),
    "shown on menu: " .. tostring(cfg.virtualtext.show_on_completion_menu),
    "ghost visible: " .. tostring(require("minuet.virtualtext").action.is_visible()),
    "debounce:      " .. cfg.debounce .. "ms, throttle: " .. cfg.throttle .. "ms",
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>ci", diagnose, { desc = "Diagnose AI completion" })

-- Force a request now. Useful for testing without waiting for the debounce.
vim.keymap.set("i", "<M-y>", function()
  require("minuet.virtualtext").action.next()
end, { noremap = true, silent = true, desc = "Request AI completion now" })

-- stale chunk state must not survive an insert session
vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    state = { ghost = nil, consumed = 0, line = nil }
  end,
  desc = "[custom.minuet] reset word-accept state",
})
