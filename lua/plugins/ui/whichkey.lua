return {
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
                    { "<leader>c", group = "Code" },
                    { "<leader>u", group = "Unity" },
                    { "<leader>p", group = "游戏项目" },
                    { "<leader>a", group = "AI" },
                    { "<leader>d", group = "调试" },
                    { "<leader>h", group = "Harpoon" },
                },
            })
        end,
    },
}
