return {
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = false,
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
}
