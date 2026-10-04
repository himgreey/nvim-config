return {
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
    },

    {
        "HiPhish/rainbow-delimiters.nvim",
        event = { "BufReadPost", "BufNewFile" },
        submodules = false,
        config = true,
        main = "rainbow-delimiters.setup",
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local autopairs = require("nvim-autopairs")
            autopairs.setup({
                check_ts = true, -- 利用 treesitter 智能判断
                ts_config = {
                    lua = { "string" },
                    cs = { "string", "comment" }, -- 在字符串、注释中不配对
                },
                fast_wrap = {
                    map = "<M-e>",
                    chars = { "{", "[", "(", '"', "'" },
                    pattern = [=[[%'%"%>%]%)%}%,]]=],
                    end_key = "$",
                    before_key = "g",
                    after_key = "e",
                    cursor_pos_before = false,
                    before_key_manual = "g",
                    after_key_manual = "E",
                    manual_position = true,
                    highlight = "Search",
                    highlight_grey = "Comment",
                },
            })

            -- 块注释配对
            local Rule = require("nvim-autopairs.rule")
            local cond = require("nvim-autopairs.conds")
            autopairs.add_rules({
                Rule("/*", "*/", { "cs", "csharp", "c", "cpp" })
                    :with_pair(cond.not_before_text("//"))
                    :with_move(cond.none())
                    :with_del(cond.none()),
            })

            -- 与 nvim-cmp 集成，避免补全时冲突
            local cmp_autopairs_ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
            if cmp_autopairs_ok then
                local cmp = require("cmp")
                cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
            end
        end,
    },

    {
        "numToStr/Comment.nvim",
        keys = {
            { "gc", mode = { "n", "v" }, desc = "Comment toggle linewise" },
            { "gb", mode = { "n", "v" }, desc = "Comment toggle blockwise" },
        },
        config = function()
            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
        end,
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
    },

    {
        "mg979/vim-visual-multi",
        branch = "master",
        init = function()
            vim.g.VM_maps = {
                ["Find Under"] = "<A-n>",
                ["Find Subword Under"] = "<A-n>",
            }
        end,
        keys = {
            { "<A-n>", mode = { "n", "v" }, desc = "Select next (multi-cursor)" },
        },
    },

    {
        "mbbill/undotree",
        keys = {
            { "<leader>uu", vim.cmd.UndotreeToggle, desc = "Toggle Undo Tree" },
        },
    },
}
