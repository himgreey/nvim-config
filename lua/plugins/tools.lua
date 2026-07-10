-- ============================================
-- 工具插件：撤销历史 + 文件标记 + Git
-- ============================================

return {
    -- 撤销历史树
    {
        "mbbill/undotree",
        keys = {
            { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle Undo Tree" },
        },
    },

    -- 快速标记文件（Harpoon 2）
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()

            -- 快捷键
            vim.keymap.set("n", "<leader>a", function()
                harpoon:list():add()
            end, { desc = "Add file to harpoon" })

            vim.keymap.set("n", "<C-e>", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end, { desc = "Open harpoon menu" })

            -- 快速跳转（1-4）
            vim.keymap.set("n", "<leader>1", function()
                harpoon:list():select(1)
            end, { desc = "Harpoon 1" })
            vim.keymap.set("n", "<leader>2", function()
                harpoon:list():select(2)
            end, { desc = "Harpoon 2" })
            vim.keymap.set("n", "<leader>3", function()
                harpoon:list():select(3)
            end, { desc = "Harpoon 3" })
            vim.keymap.set("n", "<leader>4", function()
                harpoon:list():select(4)
            end, { desc = "Harpoon 4" })
        end,
    },

    -- Git 界面
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",   -- 可选：显示 diff
            "nvim-telescope/telescope.nvim", -- 可选
        },
        config = true,
        keys = {
            { "<leader>gg", "<cmd>Neogit<CR>", desc = "Open Neogit" },
        },
    },

    -- diffview（配合 neogit 使用）
    {
        "sindrets/diffview.nvim",
        lazy = true,
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
    },
}