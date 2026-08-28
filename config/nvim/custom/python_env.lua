-- Shared python interpreter detection (pyright + dap)
local M = {}

function M.project_root(bufnr)
  bufnr = bufnr or 0
  local path = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.root(path ~= "" and path or vim.fn.getcwd(), {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "pyrightconfig.json",
    ".git",
  }) or vim.fn.getcwd()
end

-- Prefer active shell env, then project .venv / venv
function M.detect(bufnr)
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
    local p = vim.env.VIRTUAL_ENV .. "/bin/python"
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
  if vim.env.CONDA_PREFIX and vim.env.CONDA_PREFIX ~= "" then
    local p = vim.env.CONDA_PREFIX .. "/bin/python"
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
  local root = M.project_root(bufnr)
  for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
    local p = root .. "/" .. rel
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
  return nil
end

function M.conda_envs()
  local out = {}
  local base = vim.fn.expand("~/software/anaconda3/envs")
  if vim.fn.isdirectory(base) == 0 then
    return out
  end
  for name in vim.fs.dir(base) do
    local p = base .. "/" .. name .. "/bin/python"
    if vim.fn.executable(p) == 1 then
      out[#out + 1] = { label = "conda:" .. name, path = p }
    end
  end
  table.sort(out, function(a, b)
    return a.label < b.label
  end)
  return out
end

function M.choices()
  local choices = {}
  local seen = {}
  local function add(label, path)
    if path and vim.fn.executable(path) == 1 and not seen[path] then
      seen[path] = true
      choices[#choices + 1] = { label = label, path = path }
    end
  end
  local detected = M.detect(0)
  if detected then
    add("detected: " .. detected, detected)
  end
  local root = M.project_root(0)
  for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
    add("project: " .. rel, root .. "/" .. rel)
  end
  for _, env in ipairs(M.conda_envs()) do
    add(env.label, env.path)
  end
  return choices
end

function M.mason_debugpy()
  return vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
end

return M
