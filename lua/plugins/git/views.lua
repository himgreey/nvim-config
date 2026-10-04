return {
    {
        "NeogitOrg/neogit",
        cmd = "Neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
        },
        config = true,
        keys = {
            { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
        },
    },

    {
        "sindrets/diffview.nvim",
        lazy = true,
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFileHistory" },
        config = function()
            require("diffview").setup({
                diff_binaries = false,
                enhanced_diff_hl = true,
                use_icons = true,
                icons = {
                    folder_closed = "▸",
                    folder_open = "▾",
                },
                signs = {
                    fold_closed = "▸",
                    fold_open = "▾",
                },
                file_panel = {
                    listing_style = "tree",
                    tree_options = {
                        flatten_dirs = true,
                        folder_statuses = "only_folded",
                    },
                },
                keymaps = {
                    disable_defaults = false,
                    view = {
                        { "n", "<tab>", "<cmd>wincmd w<CR>", { desc = "Switch panel" } },
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
                    },
                    file_panel = {
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close" } },
                    },
                    file_history_panel = {
                        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close" } },
                    },
                },
            })
        end,
    },
}
