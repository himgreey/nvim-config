return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        config = function(_, opts)
            require("ibl").setup(opts)
            require("ibl.hooks").register(
                require("ibl.hooks").type.ACTIVE,
                function(buf) return not require("game.buffer").large(buf) end
            )
        end,
        opts = {
            indent = { char = "│", tab_char = "│" },
            scope = { enabled = true, show_start = false, show_end = false },
            exclude = {
                filetypes = { "help", "terminal", "lazy", "codecompanion", "snacks_dashboard" },
            },
        },
    },
}
