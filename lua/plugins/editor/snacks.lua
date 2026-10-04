return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        init = function() require("ui.dashboard").setup() end,
        opts = {
            -- 启动页
            dashboard = require("ui.dashboard").options(),
            -- 文件拾取器（替代 telescope）— 过滤 Unity 生成文件
            picker = {
                enabled = true,
            },
            -- 通知美化
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            -- 缩进线
            indent = {
                enabled = false, -- 缩进线由现有 indent-blankline 提供。
            },
            -- 快速跳转
            words = {
                enabled = true,
                notify = false,
            },
            -- 终端内图片预览（Windows/cmd 不支持，保持关闭）
            image = { enabled = false },
        },
        keys = {
            -- 快速打开文件
            {
                "<leader>ff",
                function() Snacks.picker.files(require("game.project").picker_opts()) end,
                desc = "Find Files",
            },
            {
                "<leader>fg",
                function() Snacks.picker.grep(require("game.project").picker_opts()) end,
                desc = "Grep",
            },
            {
                "<leader>fF",
                function() Snacks.picker.files(require("game.project").picker_opts(true)) end,
                desc = "查找所有文件（包含生成目录）",
            },
            {
                "<leader>fG",
                function() Snacks.picker.grep(require("game.project").picker_opts(true)) end,
                desc = "搜索所有文件（包含生成目录）",
            },
            { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
            { "<leader>fh", function() Snacks.picker.help() end, desc = "Help" },
            { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent Files" },
            -- 搜索当前缓冲区符号
            { "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "Document Symbols" },
            -- 快速跳转
            { "<leader>w", function() Snacks.words.jump(1, true) end, desc = "Words" },
        },
    },
}
