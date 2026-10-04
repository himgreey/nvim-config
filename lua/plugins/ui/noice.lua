return {
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {
            -- vim.notify 统一交给 Snacks；Noice 负责命令行、消息和 LSP 文档。
            notify = { enabled = false },
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                lsp_doc_border = true,
            },
            cmdline = {
                format = {
                    cmdline = { pattern = "^:", icon = "", lang = "vim" },
                    search_down = { kind = "search", pattern = "^/", icon = "🔍", lang = "regex" },
                    search_up = { kind = "search", pattern = "^%?", icon = "🔍", lang = "regex" },
                },
            },
            views = {
                cmdline_popup = { border = { style = "rounded" } },
                popupmenu = { border = { style = "rounded" } },
                hover = { border = { style = "rounded" } },
            },
        },
    },
}
