local plugins = {
    {
        "jose-elias-alvarez/null-ls.nvim",
        ft = {"python"},
        opts = function()
            return require "custom.configs.null-ls"
        end,
    },
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
    },
    {
        'williamboman/mason.nvim',
        opts = {
            ensure_installed = {
                "black",
                "pyright",
                "ruff",
                "mypy",
            }
        }
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end,
    },
    {'mbbill/undotree', lazy = false},
    {'tpope/vim-fugitive', lazy = false},

}

return plugins

