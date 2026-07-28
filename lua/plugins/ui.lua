-- ============================================
-- UI 相关插件
-- ============================================

return {
    -- 主题
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                show_end_of_buffer = false,
                term_colors = true,
                dim_inactive = {
                    enabled = true,
                    shade = "dark",
                    percentage = 0.15,
                },
                styles = {
                    comments = { "italic" },
                    conditionals = { "italic" },
                },
                integrations = {
                    telescope = true,
                    nvimtree = true,
                    treesitter = true,
                    lsp_trouble = true,
                    which_key = true,
                    indent_blankline = {
                        enabled = true,
                        colored_indent_levels = false,
                    },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },

    -- 状态栏
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
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
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
            })
        end,
    },

    -- 图标库
    {
        "nvim-tree/nvim-web-devicons",
        -- lazy = false,  -- 改为 false 确保立即加载
    },

    -- 缓冲区标签栏
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup({
                options = {
                    numbers = "none",
                    close_command = "bdelete! %d",
                    right_mouse_command = "bdelete! %d",
                    left_mouse_command = "buffer %d",
                    middle_mouse_command = nil,
                    indicator = {
                        icon = "▎",
                        style = "icon",
                    },
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
                        local icon = level:match("error") and " " or " "
                        return icon .. count
                    end,
                    show_buffer_icons = true,
                    show_buffer_close_icons = true,
                    show_close_icon = true,
                    show_tab_indicators = true,
                    persist_buffer_sort = true,
                    separator_style = "thin",
                    enforce_regular_tabs = false,
                    always_show_bufferline = true,
                    sort_by = "insert_at_end",
                },
                highlights = {
                    fill = {
                        fg = "#cba6f7",
                        bg = "#1e1e2e",
                    },
                    background = {
                        fg = "#6c7086",
                        bg = "#1e1e2e",
                    },
                    buffer_selected = {
                        bold = true,
                        italic = false,
                    },
                },
            })
        end,
    },

    -- 缩进指示线
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
        config = function()
            require("ibl").setup({
                indent = {
                    char = "│",
                    tab_char = "│",
                },
                scope = {
                    enabled = true,
                    show_start = false,
                    show_end = false,
                },
                exclude = {
                    filetypes = { "help", "terminal", "lazy", "TelescopePrompt" },
                },
            })
        end,
    },

    -- nvim-tree
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<C-n>", "<cmd>NvimTreeToggle<CR>", mode = "n", desc = "Toggle file tree" },
        },
        config = function()
            require("nvim-tree").setup({})
        end,
    },

    -- 美化弹窗
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        config = function()
            require("noice").setup({
                lsp = {
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                    hover = { enabled = true },
                    signature = { enabled = true },
                    progress = { enabled = true },
                },
                presets = {
                    bottom_search = true,
                    command_palette = true,
                    long_message_to_split = true,
                    inc_rename = true,
                    lsp_doc_border = true,
                },
                cmdline = {
                    view = "cmdline_popup",
                    format = {
                        cmdline = { pattern = "^:", icon = "", lang = "vim" },
                        search_down = { kind = "search", pattern = "^/", icon = "🔍", lang = "regex" },
                        search_up = { kind = "search", pattern = "^%?", icon = "🔍", lang = "regex" },
                    },
                },
                views = {
                    cmdline_popup = {
                        border = { style = "rounded" },
                    },
                    popupmenu = {
                        border = { style = "rounded" },
                    },
                    hover = {
                        border = { style = "rounded" },
                    },
                    help = {
                        border = { style = "rounded" },
                    },
                },
                routes = {
                    {
                        filter = { event = "msg_show", kind = "" },
                        opts = { skip = true },
                    },
                },
            })
        end,
    },
}