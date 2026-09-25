local nvlsp = require("nvchad.configs.lspconfig")
local pyenv = require("custom.python_env")

-- ty settings shape: settings.ty.configuration.environment.python
local function ty_settings(path)
  return { ty = { configuration = { environment = { python = path } } } }
end

local function set_ty_python(path)
  local clients = vim.lsp.get_clients({ name = "ty" })
  if #clients == 0 then
    vim.notify("ty not attached — open a .py file first, then :PythonEnv again", vim.log.levels.WARN)
    return
  end
  for _, client in ipairs(clients) do
    client.settings = vim.tbl_deep_extend("force", client.settings or {}, ty_settings(path))
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  end
  vim.notify("ty python → " .. path, vim.log.levels.INFO)
end

local function pick_python()
  local choices = pyenv.choices()
  if #choices == 0 then
    vim.notify("no python envs found (.venv / venv; create one with `uv venv`)", vim.log.levels.WARN)
    return
  end
  local lines = { "Pick python for ty:" }
  for i, item in ipairs(choices) do
    lines[#lines + 1] = string.format("%d. %s", i, item.label)
  end
  local n = vim.fn.inputlist(lines)
  if n >= 1 and n <= #choices then
    set_ty_python(choices[n].path)
  end
end

local servers = {
  "ty", -- types, hover, completion (replaces pyright + mypy); finds $VIRTUAL_ENV / .venv itself
  "ruff", -- lint + format (replaces black)
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
  if name == "ruff" then
    -- only used when the project has no ruff config of its own
    opts.init_options = { settings = { lineLength = 120 } }
  end
  vim.lsp.config(name, opts)
  vim.lsp.enable(name)
end

-- NvChad defaults() sets nerd-font diagnostic glyphs — replace after
require("custom.configs.noicons").diagnostic_signs()

vim.api.nvim_create_user_command("PythonEnv", function(opts)
  if opts.args ~= "" then
    set_ty_python(opts.args)
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
  desc = "Set ty python environment (picker if no arg)",
})

vim.keymap.set("n", "<leader>pv", pick_python, { desc = "Pick python env (ty)" })

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

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false -- defer to ty
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("RuffFormat" .. ev.buf, { clear = true }),
        buffer = ev.buf,
        callback = function()
          vim.lsp.buf.format({ bufnr = ev.buf, name = "ruff" })
        end,
      })
    end
  end,
})
