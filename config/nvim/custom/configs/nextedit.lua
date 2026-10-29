-- Next-edit prediction: rename a symbol here, and this offers the same rename
-- at the other call sites. Cursor's tab-tab-tab flow, not a completion.
--
-- Runs against Fireworks through nextedit's generic OpenAI-dialect provider. The
-- plugin builds a Rust sidecar on install, so the first `:Lazy sync` after this
-- file appears takes a few minutes.
--
--   <M-a>   accept the prediction (jumps first when it is far away)
--   <C-]>   dismiss, and stay quiet until the lines change
--   :NextEditToggle   pause it
--
-- It shares the FIREWORKS_API_KEY with minuet, so it only runs when minuet is
-- the active backend. Set `nes = false` in custom/ai_local.lua to keep the key
-- for completions only.

local ai = require "custom.configs.ai"

if not ai.nes then
  return
end

local key = vim.env[ai.api_key_env]
if not key or key == "" then
  vim.notify(("next-edit prediction is on but %s is unset"):format(ai.api_key_env), vim.log.levels.WARN)
  return
end

-- Read from the environment by the sidecar, not a Lua option. The model is a
-- reasoning model; left at its default effort it spends the budget thinking and
-- the edit either arrives late or not at all. Verified accepted by Fireworks.
vim.env.NEXTEDIT_REASONING_EFFORT = "none"

require("nextedit").setup {
  -- "mistral" only selects a default endpoint and model; both are overridden
  -- below. It is used instead of "openai" because the openai flavor attaches a
  -- `prediction` field that Fireworks answers with HTTP 500, and the plugin
  -- only retries without it on HTTP 400 — so "openai" fails outright here.
  provider = "mistral",
  api_url = ai.endpoint,
  api_key = key,
  model = ai.model,
  -- "typing" also predicts mid-edit; it needs a faster model than a flash chat
  -- model, so start at edit boundaries and raise it if the latency holds up.
  trigger = "boundary",
  multiline = true,
  debounce_ms = 300,
  context_lines = 40,
  outline = true,
  cross_file = true,
  accept_key = "<M-a>",
  dismiss_key = "<C-]>",
  sign_text = ">",
  -- replaces the plugin default, so the defaults are restated here
  deny_paths = {
    "%.env",
    "%.pem$",
    "secret",
    "credential",
    "%.ssh/",
    "id_rsa",
    "id_ed25519",
  },
}
