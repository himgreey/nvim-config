return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>ha", desc = "Harpoon：添加文件" },
            { "<C-e>", desc = "Harpoon 菜单" },
            { "<leader>1", desc = "Harpoon 1" },
            { "<leader>2", desc = "Harpoon 2" },
            { "<leader>3", desc = "Harpoon 3" },
            { "<leader>4", desc = "Harpoon 4" },
        },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()

            vim.keymap.set(
                "n",
                "<leader>ha",
                function() harpoon:list():add() end,
                { desc = "Add file to harpoon" }
            )

            vim.keymap.set(
                "n",
                "<C-e>",
                function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
                { desc = "Open harpoon menu" }
            )

            for i = 1, 4 do
                vim.keymap.set(
                    "n",
                    "<leader>" .. i,
                    function() harpoon:list():select(i) end,
                    { desc = "Harpoon " .. i }
                )
            end
        end,
    },

    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        cmd = {
            "NvimTreeToggle",
            "NvimTreeOpen",
            "NvimTreeFindFile",
            "NvimTreeFindFileToggle",
            "NvimTreeFocus",
        },
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            {
                "<C-n>",
                "<cmd>NvimTreeFindFileToggle!<CR>",
                mode = "n",
                desc = "文件树：定位当前文件",
            },
        },
        config = function()
            require("nvim-tree").setup({
                hijack_netrw = false, -- netrw 已在 config.options 中禁用。
                view = {
                    width = function() return require("ui.layout").tree_width() end,
                    preserve_window_proportions = true,
                },
                renderer = { root_folder_label = function(path) return vim.fs.basename(path) end },
                -- Windows 上的同步 Git 查询会阻塞 Unity 大项目的打开和定位。
                git = { enable = false },
                filters = {
                    custom = function(path) return require("game.project").excluded(path) end,
                },
                update_focused_file = {
                    enable = true,
                    update_root = { enable = true },
                },
            })
        end,
    },
}
