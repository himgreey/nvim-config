return {
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>cf",
                function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
                mode = { "n", "v" },
                desc = "格式化代码",
            },
            {
                "<leader>uf",
                function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
                desc = "格式化 C#",
            },
        },
        opts = {
            notify_on_error = false,
            format_on_save = function(bufnr)
                local disable_filetypes = {
                    "markdown",
                    "toml",
                    "c",
                    "cpp",
                    "gdscript",
                    "gdshader",
                    "hlsl",
                    "yaml",
                    "godot_resource",
                }
                if vim.tbl_contains(disable_filetypes, vim.bo[bufnr].filetype) then return nil end
                return {
                    timeout_ms = 1500,
                    lsp_format = "fallback",
                }
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                cs = { "csharpier" },
                csharp = { "csharpier" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                gdscript = { "gdformat" },
                python = { "isort", "black" },
                javascript = { "prettierd", "prettier", stop_after_first = true },
                typescript = { "prettierd", "prettier", stop_after_first = true },
                json = { "prettierd", "prettier", stop_after_first = true },
                yaml = { "yamlfix" },
                go = { "goimports", "gofumpt" },
                rust = { "rustfmt" },
                sh = { "shfmt" },
            },
        },
    },
}
