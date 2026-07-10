-- ============================================
-- 实用工具：快捷键提示 + 格式化 + 注释
-- ============================================

return {
    -- 快捷键提示
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup({
                preset = "helix",
                delay = 0,
                icons = {
                    mappings = vim.g.have_nerd_font,
                    keys = vim.g.have_nerd_font and {} or { Up = "↑", Down = "↓" },
                },
                spec = {
                    { "<leader>g", group = "Git" },
                    { "<leader>f", group = "Find" },
                },
            })
        end,
    },

    -- 代码格式化
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "Format buffer",
            },
        },
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                -- 控制保存时是否自动格式化
                local disable_filetypes = { "markdown", "toml" }
                if vim.tbl_contains(disable_filetypes, vim.bo[bufnr].filetype) then
                    return nil
                end
                return {
                    timeout_ms = 500,
                    lsp_fallback = true,
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                javascript = { { "prettier", "prettierd" } },
                typescript = { { "prettier", "prettierd" } },
                json = { { "prettier", "prettierd" } },
                yaml = { "yamlfix" },
                go = { "goimports", "gofumpt" },
                rust = { "rustfmt" },
                sh = { "shfmt" },
            },
        },
    },

    -- 代码注释
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

    -- 多光标编辑
    {
        "mg979/vim-visual-multi",
        branch = "master",
        keys = {
            { "<C-n>", mode = { "n", "v" }, desc = "Select next" },
            { "n", mode = { "v" }, desc = "Skip" },
        },
    },
}