local plugins = {
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
    },
    {
        -- package list lives in chadrc M.mason.pkgs (mason v2 + NvChad MasonInstallAll)
        "mason-org/mason.nvim",
        opts = {
            ui = {
                icons = {
                    package_pending = "P",
                    package_installed = "*",
                    package_uninstalled = "o",
                },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        -- don't wait for NvChad User FilePost (autocmds often never fire in this bootstrap)
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require "custom.configs.lspconfig"
        end,
    },
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        lazy = false,
        config = function()
            require "custom.configs.harpoon"
        end,
    },
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "mfussenegger/nvim-dap-python",
            {
                "rcarriga/nvim-dap-ui",
                dependencies = { "nvim-neotest/nvim-nio" },
            },
        },
        keys = {
            { "<F5>", desc = "DAP continue" },
            { "<F9>", desc = "DAP toggle breakpoint" },
            { "<leader>db", desc = "DAP toggle breakpoint" },
            { "<leader>dc", desc = "DAP continue" },
            { "<leader>du", desc = "DAP UI toggle" },
        },
        config = function()
            require "custom.configs.dap"
        end,
    },
    -- VS Code-style: highlight other instances of word under cursor
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("illuminate").configure({
                delay = 150,
                under_cursor = true,
                large_file_cutoff = 3000,
                min_count_to_highlight = 2,
            })
            local hl = { underline = true }
            vim.api.nvim_set_hl(0, "IlluminatedWordText", hl)
            vim.api.nvim_set_hl(0, "IlluminatedWordRead", hl)
            vim.api.nvim_set_hl(0, "IlluminatedWordWrite", hl)
        end,
    },
    {
        "stevearc/oil.nvim",
        lazy = false,
        opts = {
            view_options = { show_hidden = true },
            columns = { "permissions", "size", "mtime" }, -- no icon column
            keymaps = {
                ["<C-h>"] = false,
                ["<C-l>"] = false,
            },
        },
        keys = {
            {
                "-",
                function()
                    require("oil").open()
                end,
                desc = "Oil open parent",
            },
        },
    },
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = function()
            return { icons = require("custom.configs.noicons").trouble_icons() }
        end,
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Trouble diagnostics",
            },
            {
                "<leader>xr",
                "<cmd>Trouble lsp_references toggle<cr>",
                desc = "Trouble references",
            },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        opts = function()
            local opts = require "nvchad.configs.nvimtree"
            opts.renderer = opts.renderer or {}
            opts.renderer.icons = require("custom.configs.noicons").nvim_tree_icons()
            return opts
        end,
    },
    {
        "nvim-tree/nvim-web-devicons",
        opts = function()
            require("custom.configs.noicons").neuter_devicons()
            return { color_icons = false, default = true }
        end,
        config = function(_, opts)
            require("custom.configs.noicons").neuter_devicons()
            pcall(require("nvim-web-devicons").setup, opts)
        end,
    },
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        opts = {},
    },
    -- no nerd-font glyphs (rects / mojibake in default terminal fonts)
    {
        "folke/which-key.nvim",
        opts = function()
            dofile(vim.g.base46_cache .. "whichkey")
            return {
                icons = {
                    mappings = false,
                    rules = false,
                    breadcrumb = ">",
                    separator = "-",
                    group = "+",
                    ellipsis = "...",
                    keys = {
                        Up = "Up",
                        Down = "Down",
                        Left = "Left",
                        Right = "Right",
                        C = "C-",
                        M = "M-",
                        D = "D-",
                        S = "S-",
                        CR = "CR",
                        Esc = "Esc",
                        ScrollWheelDown = "SwD",
                        ScrollWheelUp = "SwU",
                        NL = "NL",
                        BS = "BS",
                        Space = "SPC",
                        Tab = "TAB",
                        F1 = "F1",
                        F2 = "F2",
                        F3 = "F3",
                        F4 = "F4",
                        F5 = "F5",
                        F6 = "F6",
                        F7 = "F7",
                        F8 = "F8",
                        F9 = "F9",
                        F10 = "F10",
                        F11 = "F11",
                        F12 = "F12",
                    },
                },
            }
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
                desc = "Find: files",
            },
            {
                "<leader>fg",
                function()
                    require("fff").live_grep()
                end,
                desc = "Find: grep (live, project-wide)",
            },
            {
                "<leader>fz",
                function()
                    require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
                end,
                desc = "Find: grep, fuzzy",
            },
            {
                "<leader>fw",
                function()
                    require("fff").live_grep_under_cursor()
                end,
                mode = { "n", "x" },
                desc = "Find: word/selection under cursor",
            },
        },
    },
    {"mbbill/undotree", lazy = false},
    {"tpope/vim-fugitive", lazy = false},
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        opts = {
            enhanced_diff_hl = true,
            use_icons = false, -- no nerd-font glyphs, matches rest of config
            view = {
                merge_tool = { layout = "diff3_horizontal" },
            },
        },
        keys = {
            {
                "<leader>gd",
                function()
                    -- toggle: close if a diffview is open, else open (merge-conflict view when mid-merge)
                    if next(require("diffview.lib").views) == nil then
                        vim.cmd("DiffviewOpen")
                    else
                        vim.cmd("DiffviewClose")
                    end
                end,
                desc = "Git: toggle diffview / conflict resolution",
            },
            {
                "<leader>gh",
                "<cmd>DiffviewFileHistory %<CR>",
                desc = "Git: file history (current file)",
            },
            {
                "<leader>gH",
                "<cmd>DiffviewFileHistory<CR>",
                desc = "Git: file history (repo)",
            },
        },
    },
    {"gennaro-tedesco/nvim-jqx", lazy = true, ft={"json"}},
    { "preservim/vim-markdown", ft = { "markdown" }, init = function()
        vim.g.vim_markdown_folding_disabled = 1
    end },
    {
        "nvim-treesitter/nvim-treesitter",
        override = true,
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("custom.configs.treesitter")
            ts.setup()
            ts.install_parsers()
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "_" },
                changedelete = { text = "~" },
            },
        },
    },
    -- --- Pinned NvChad stack -------------------------------------------------
    -- setup.sh clones NvChad into ~/.config/nvim once and never updates it, but
    -- base46 auto-updates on every `Lazy sync`. When base46 ran ahead of the
    -- clone, indent-blankline broke: NvChad still asked for the highlight groups
    -- IblChar and IblScopeChar, and base46 had stopped defining them, so
    -- ibl.setup() raised "No highlight group 'IblChar' found".
    --
    -- These move together as one verified set:
    --   NvChad  87d6a41  v2.5 tip, "fix: use ibl default highlight groups"
    --   base46  d870ec8  v3.0 tip
    --   ~/.config/nvim clone at 87d6a41
    --
    -- To move the pin deliberately:
    --   1. git -C ~/.config/nvim fetch --depth 1 origin refs/heads/v2.5
    --      git -C ~/.config/nvim reset --hard origin/v2.5
    --   2. update both SHAs below so the clone and the NvChad plugin stay in step
    --   3. :Lazy sync
    --
    -- NvChad's own spec lives in the clone and in init.lua; this merges a commit
    -- onto it. base46 is declared by NvChad, so the pin has to live here.
    {
        "NvChad/NvChad",
        commit = "87d6a41ec07ab995de912a892749b6b4805ad2b3",
    },
    {
        "nvchad/base46",
        commit = "d870ec89a7b2f28c4accce515f97b7bcc5b9d200",
    },
    -- Cursor-style multi-line ghost-text tab completion.
    -- custom/configs/ai.lua picks exactly one of these; see that file for the
    -- resolution rules. Two engines on one line would fight each other.
    -- Loaded eagerly, not on InsertEnter. minuet arms its auto-trigger from a
    -- FileType autocmd registered in setup(); a buffer that already fired
    -- FileType never sees it, so the flag stays nil and no ghost text appears.
    -- Eager loading registers the autocmd before the first file is opened.
    {
        "milanglacier/minuet-ai.nvim",
        lazy = false,
        cond = function()
            return require("custom.configs.ai").using "minuet"
        end,
        config = function()
            require "custom.configs.minuet"
        end,
    },
    {
        "supermaven-inc/supermaven-nvim",
        event = "InsertEnter",
        cond = function()
            return require("custom.configs.ai").using "supermaven"
        end,
        config = function()
            require "custom.configs.supermaven"
        end,
    },
    -- Cursor-style next-edit prediction: rename a symbol here, fix the call
    -- sites there. Shares FIREWORKS_API_KEY with minuet, so it is off unless
    -- custom/ai_local.lua says otherwise.
    {
        "zenodea/nextedit.nvim",
        build = "cd server && cargo build --release",
        event = { "BufReadPost", "BufNewFile" },
        cond = function()
            return require("custom.configs.ai").nes
        end,
        config = function()
            require "custom.configs.nextedit"
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        lazy = false,
        opts = {
            enabled = true,
            -- no nerd-font icons; keeps rendering readable in the default terminal font
            code = { sign = false, width = "block", right_pad = 1 },
            heading = { sign = false, icons = {} },
            checkbox = { enabled = false },
            link = { enabled = false },
            sign = { enabled = false },
        },
        keys = {
            {
                "<leader>md",
                function()
                    vim.cmd("RenderMarkdown toggle")
                    local on = require("render-markdown").get()
                    vim.notify(on and "Markdown rendering: ON" or "Markdown rendering: OFF", vim.log.levels.INFO)
                end,
                desc = "Toggle rendered markdown",
            },
        },
    },
}

return plugins
