return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "auto",
                component_separators = "",
                section_separators = "",
                disabled_filetypes = { "NvimTree" },
                globalstatus = true,
            },
            sections = {
                lualine_a = { { "mode", padding = { left = 2, right = 1 } } },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { { "location", padding = { left = 1, right = 2 } } },
            },
        },
    },
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                -- 不用 bdelete!，让未保存内容获得 Vim 的保护。
                close_command = "bdelete %d",
                right_mouse_command = "bdelete %d",
                indicator = { icon = "▎", style = "icon" },
                buffer_close_icon = "✕",
                modified_icon = "●",
                close_icon = "✕",
                left_trunc_marker = "◀",
                right_trunc_marker = "▶",
                max_name_length = 30,
                max_prefix_length = 30,
                tab_size = 20,
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                    return (level:match("error") and " " or " ") .. count
                end,
                separator_style = "thin",
                sort_by = "insert_at_end",
            },
            highlights = {
                fill = { fg = "#cba6f7", bg = "#1e1e2e" },
                background = { fg = "#6c7086", bg = "#1e1e2e" },
                buffer_selected = { bold = true, italic = false },
            },
        },
    },
}
