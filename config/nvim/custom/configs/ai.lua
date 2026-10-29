-- Which inline-completion backend runs, and which model it uses.
--
--   minuet      fill-in-the-middle against Fireworks. Needs FIREWORKS_API_KEY.
--   supermaven  Supermaven's hosted model. Free tier, no key required.
--
-- Resolution order, first hit wins:
--   1. NVIM_AI_BACKEND environment variable ("minuet" or "supermaven")
--   2. custom/ai_local.lua -> { backend = "...", model = "...", nes = true }
--   3. auto: minuet when FIREWORKS_API_KEY is set, else supermaven
--
-- setup.sh writes custom/ai_local.lua, which is gitignored. Each machine
-- therefore keeps its own choice without touching tracked files.

local M = {}

M.endpoint = "https://api.fireworks.ai/inference/v1"
M.api_key_env = "FIREWORKS_API_KEY"
M.default_model = "accounts/fireworks/models/deepseek-v4p1-flash"

local VALID = { minuet = true, supermaven = true }

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

  if vim.env.FIREWORKS_API_KEY and vim.env.FIREWORKS_API_KEY ~= "" then
    return "minuet"
  end
  return "supermaven"
end

M.backend = pick()

if M.model == nil then
  M.model = M.default_model
end

-- Next-edit prediction needs the same key as minuet, so it follows the backend
-- unless ai_local.lua says otherwise.
if M.nes == nil then
  M.nes = M.backend == "minuet"
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
