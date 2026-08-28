local nvlsp = require("nvchad.configs.lspconfig")
local pyenv = require("custom.python_env")

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
    client.config.settings = client.config.settings or {}
    client.config.settings.python = client.config.settings.python or {}
    client.config.settings.python.pythonPath = path
    client:notify("workspace/didChangeConfiguration", { settings = nil })
  end
  vim.notify("pyright python → " .. path, vim.log.levels.INFO)
end

local function pick_python()
  local choices = pyenv.choices()
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
      local py = pyenv.detect(0)
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
    for _, item in ipairs(pyenv.choices()) do
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
