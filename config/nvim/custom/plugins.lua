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
    {
        "dmtrKovalenko/fff.nvim",
        build = function()
            -- downloads a prebuilt binary or falls back to cargo build
            require("fff.download").download_or_build_binary()
        end,
        lazy = false,
        opts = {
            debug = {
                enabled = false,
                show_scores = false,
            },
        },
        keys = {
            {
                "<leader>ff",
                function()
                    require("fff").find_files()
                end,
                desc = "FFF find files",
            },
            {
                "<leader>fw",
                function()
                    require("fff").live_grep()
                end,
                desc = "FFF live grep",
            },
            {
                "<leader>fz",
                function()
                    require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
                end,
                desc = "FFF fuzzy live grep",
            },
            {
                "<leader>fW",
                function()
                    require("fff").live_grep_under_cursor()
                end,
                mode = { "n", "x" },
                desc = "FFF grep word/selection",
            },
        },
    },
    {'mbbill/undotree', lazy = false},
    {'tpope/vim-fugitive', lazy = false},
    {'gennaro-tedesco/nvim-jqx', lazy = true, ft={"json"}},
    { "preservim/vim-markdown", ft = { "markdown" } },
}

return plugins

