local nvlsp = require("nvchad.configs.lspconfig")

local function project_root(bufnr)
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
local function detect_python(bufnr)
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
  local root = project_root(bufnr)
  for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
    local p = root .. "/" .. rel
    if vim.fn.executable(p) == 1 then
      return p
    end
  end
  return nil
end

local function conda_envs()
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

local function python_choices()
  local choices = {}
  local seen = {}
  local function add(label, path)
    if path and vim.fn.executable(path) == 1 and not seen[path] then
      seen[path] = true
      choices[#choices + 1] = { label = label, path = path }
    end
  end
  local detected = detect_python(0)
  if detected then
    add("detected: " .. detected, detected)
  end
  local root = project_root(0)
  for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
    add("project: " .. rel, root .. "/" .. rel)
  end
  for _, env in ipairs(conda_envs()) do
    add(env.label, env.path)
  end
  return choices
end

local function set_pyright_python(path)
  local clients = vim.lsp.get_clients({ name = "pyright" })
  if #clients == 0 then
    vim.notify("pyright not attached — open a .py file first, then :PythonEnv again", vim.log.levels.WARN)
    return
  end
  for _, client in ipairs(clients) do
    if not client.settings then
      client.settings = {}
    end
    client.settings.python = client.settings.python or {}
    client.settings.python.pythonPath = path
    -- also keep config.settings in sync for older clients
    client.config.settings = client.config.settings or {}
    client.config.settings.python = client.config.settings.python or {}
    client.config.settings.python.pythonPath = path
    client:notify("workspace/didChangeConfiguration", { settings = nil })
  end
  vim.notify("pyright python → " .. path, vim.log.levels.INFO)
end

-- Numbered list picker (works without telescope / fancy ui.select)
local function pick_python()
  local choices = python_choices()
  if #choices == 0 then
    vim.notify("no python envs found under ~/software/anaconda3/envs or .venv", vim.log.levels.WARN)
    return
  end
  local lines = { "Pick python for pyright:" }
  for i, item in ipairs(choices) do
    lines[#lines + 1] = string.format("%d. %s", i, item.label)
  end
  local n = vim.fn.inputlist(lines)
  if n >= 1 and n <= #choices then
    set_pyright_python(choices[n].path)
  end
end

local servers = {
  "pyright",
  "bashls",
  "jsonls",
  "yamlls",
  "marksman",
  "ts_ls",
  "rust_analyzer",
  "gopls",
}

for _, name in ipairs(servers) do
  local opts = {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
  if name == "pyright" then
    opts.before_init = function(_, config)
      local py = detect_python(0)
      if py then
        config.settings = config.settings or {}
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = py
      end
    end
  end
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end

-- NvChad defaults() sets nerd-font diagnostic glyphs — replace after
require("custom.configs.noicons").diagnostic_signs()

-- Global: works even before remembering LSP buffer commands
vim.api.nvim_create_user_command("PythonEnv", function(opts)
  if opts.args ~= "" then
    set_pyright_python(opts.args)
    return
  end
  pick_python()
end, {
  nargs = "?",
  complete = function(arglead)
    local out = {}
    for _, item in ipairs(python_choices()) do
      if vim.startswith(item.path, arglead) or vim.startswith(item.label, arglead) then
        out[#out + 1] = item.path
      end
    end
    return out
  end,
  desc = "Set pyright pythonPath (picker if no arg)",
})

vim.keymap.set("n", "<leader>pv", pick_python, { desc = "Pick python env (pyright)" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("CustomLspMaps", { clear = true }),
  callback = function(ev)
    local opts = function(desc)
      return { buffer = ev.buf, desc = "LSP " .. desc }
    end
    local map = vim.keymap.set
    map("n", "gr", vim.lsp.buf.references, opts("references"))
    map("n", "gI", vim.lsp.buf.implementation, opts("implementation"))
    map("n", "K", vim.lsp.buf.hover, opts("hover"))
    map("n", "<leader>ca", vim.lsp.buf.code_action, opts("code action"))
    map("n", "[d", vim.diagnostic.goto_prev, opts("prev diagnostic"))
    map("n", "]d", vim.diagnostic.goto_next, opts("next diagnostic"))
  end,
})
