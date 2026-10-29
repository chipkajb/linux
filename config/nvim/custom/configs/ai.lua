-- Which inline-completion backend runs, and which model it uses.
--
--   minuet      fill-in-the-middle against Fireworks. Needs FIREWORKS_API_KEY.
--   supermaven  Supermaven's hosted model. Free tier, no key required.
--
-- Resolution order, first hit wins:
--   1. NVIM_AI_BACKEND environment variable ("minuet" or "supermaven")
--   2. custom/ai_local.lua -> { backend = "...", model = "...", nes = true }
--   3. auto: minuet when the Fireworks key is available, else supermaven
--
-- A choice of minuet on a machine with no key falls back to supermaven with a
-- warning, so a pinned config cannot break startup on a second machine.

local M = {}

M.endpoint = "https://api.fireworks.ai/inference/v1"
M.api_key_env = "FIREWORKS_API_KEY"
M.default_model = "accounts/fireworks/models/deepseek-v4p1-flash"

local ENV_NAME = M.api_key_env
local SECRETS_FILE = "~/.zsh_secrets"
local VALID = { minuet = true, supermaven = true }

--- The Fireworks key: the environment first, then ~/.zsh_secrets.
---
--- Neovim started from a desktop launcher or a window-manager keybinding has no
--- shell environment, so a key that only exists in a terminal session would make
--- the backend unavailable there. minuet reads the key from the environment
--- itself, so a key found in the file is put into the environment.
local function resolve_key()
  local from_env = vim.env[ENV_NAME]
  if from_env and from_env ~= "" then
    return from_env
  end

  local path = vim.fn.expand(SECRETS_FILE)
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    local value = line:match("^%s*export%s+" .. ENV_NAME .. "%s*=%s*(.+)$")
      or line:match("^%s*" .. ENV_NAME .. "%s*=%s*(.+)$")
    if value then
      value = value:gsub("%s+#.*$", ""):gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1"):gsub("%s+$", "")
      if value ~= "" then
        vim.env[ENV_NAME] = value
        return value
      end
    end
  end

  return nil
end

local function read_local()
  local path = vim.fn.stdpath "config" .. "/lua/custom/ai_local.lua"
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  local ok, value = pcall(dofile, path)
  if not ok then
    vim.notify("custom/ai_local.lua failed to load: " .. tostring(value), vim.log.levels.WARN)
    return {}
  end
  if type(value) ~= "table" then
    vim.notify("custom/ai_local.lua must return a table", vim.log.levels.WARN)
    return {}
  end
  return value
end

M.api_key = resolve_key()

local function pick()
  local env = vim.env.NVIM_AI_BACKEND
  if env and env ~= "" then
    if VALID[env] then
      return env
    end
    vim.notify(
      ('NVIM_AI_BACKEND must be "minuet" or "supermaven", got "%s"; ignoring it'):format(env),
      vim.log.levels.WARN
    )
  end

  local local_cfg = read_local()
  if VALID[local_cfg.backend] then
    M.model = local_cfg.model or M.default_model
    M.nes = local_cfg.nes
    return local_cfg.backend
  end

  if M.api_key then
    return "minuet"
  end
  return "supermaven"
end

M.backend = pick()

-- A pin or an override can name minuet on a machine with no key. Degrade rather
-- than erroring on every start.
if M.backend == "minuet" and not M.api_key then
  vim.notify_once(
    ENV_NAME .. " is not set, so minuet cannot run; using supermaven instead",
    vim.log.levels.WARN
  )
  M.backend = "supermaven"
end

if M.model == nil then
  M.model = M.default_model
end

-- Next-edit prediction needs the same key as minuet, so it follows the backend
-- unless ai_local.lua says otherwise.
if M.nes == nil then
  M.nes = M.backend == "minuet"
end

-- ai_local.lua can force nes on while the backend is supermaven, or with no key.
if M.nes and not M.api_key then
  vim.notify_once("next-edit prediction needs " .. ENV_NAME .. "; it is off", vim.log.levels.WARN)
  M.nes = false
end

--- True when `name` is the active backend.
function M.using(name)
  return M.backend == name
end

--- Report the active backend and model. Bound to <leader>ci.
function M.info()
  vim.notify(("inline completion: %s\nmodel: %s\nnext-edit: %s"):format(M.backend, M.model, tostring(M.nes)), vim.log.levels.INFO)
end

return M
