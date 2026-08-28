local nvlsp = require("nvchad.configs.lspconfig")

-- servers beyond NvChad's default lua_ls
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
  vim.lsp.config(name, {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  })
  vim.lsp.enable(name)
end

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
