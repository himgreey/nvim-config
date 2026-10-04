return {
    {
        "folke/trouble.nvim",
        opts = {},
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<CR>",
                desc = "Toggle diagnostics",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
                desc = "Buffer diagnostics",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<CR>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<CR>",
                desc = "LSP (Trouble)",
            },
        },
    },
}
