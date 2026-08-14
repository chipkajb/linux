local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local null_ls = require("null-ls")

-- Prefer project venv tools so mypy picks up plugins like pydantic.mypy.
local venv_bin = ".venv/bin"

local opts = {
    sources = {
        null_ls.builtins.formatting.black.with({ prefer_local = venv_bin }),
        null_ls.builtins.diagnostics.mypy.with({ prefer_local = venv_bin }),
    },
    on_attach = function (client, bufnr)
        if client:supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds({
                group = augroup,
                buffer = bufnr,
            })
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function ()
                    vim.lsp.buf.format({ bufnr = bufnr})
                end
            })
        end
    end,
}

return opts
