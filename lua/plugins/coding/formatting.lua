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
                if require("game.buffer").large(bufnr) then return nil end
                if vim.tbl_contains({ "cs", "csharp" }, vim.bo[bufnr].filetype) then return nil end
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
            -- C# formatter 冷启动较慢；保存后异步格式化并写回，编辑过程中由 Conform 处理并发修改。
            format_after_save = function(bufnr)
                if require("game.buffer").large(bufnr) then return nil end
                if vim.tbl_contains({ "cs", "csharp" }, vim.bo[bufnr].filetype) then
                    return { lsp_format = "fallback" }
                end
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
