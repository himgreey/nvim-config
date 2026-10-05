return {
    {
        "olimorris/codecompanion.nvim",
        branch = "main", -- 即使 checkout 在固定 tag，也明确 Lazy 用于更新的分支。
        version = "v19.25.0",
        cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
        dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
        keys = {
            {
                "<leader>aa",
                function() require("ai.codex").actions(false) end,
                desc = "Codex 操作菜单",
            },
            {
                "<leader>aa",
                function() require("ai.codex").actions(true) end,
                mode = "v",
                desc = "Codex 选中代码操作",
            },
            { "<leader>ac", function() require("ai.codex").open() end, desc = "Codex 聊天" },
            {
                "<leader>ai",
                function() require("ai.composer").open(nil, true) end,
                desc = "AI 消息输入框",
            },
            {
                "<leader>am",
                function() require("ai.panel").models() end,
                desc = "Codex 选择模型",
            },
            {
                "<leader>ah",
                function() require("ai.panel").history(false) end,
                desc = "Codex 项目历史",
            },
            {
                "<leader>aH",
                function() require("ai.panel").history(true) end,
                desc = "Codex 全部本地历史",
            },
            { "<leader>an", function() require("ai.codex").new() end, desc = "Codex 新建对话" },
            {
                "<leader>ae",
                function() require("ai.codex").edit(false) end,
                desc = "让 Codex 修改当前文件",
            },
            {
                "<leader>ae",
                function() require("ai.codex").edit(true) end,
                mode = "v",
                desc = "让 Codex 修改选中代码",
            },
            {
                "<leader>as",
                function() require("ai.codex").add(true) end,
                mode = "v",
                desc = "将选中代码加入 Codex 聊天",
            },
        },
        opts = function()
            local base = (
                vim.env.AI_BASE_URL
                or vim.env.OPENAI_BASE_URL
                or "https://api.openai.com/v1"
            ):gsub("/+$", "")
            local model = vim.env.AI_MODEL or "gpt-4.1"
            return {
                adapters = {
                    acp = {
                        codex = function()
                            return require("codecompanion.adapters.acp").extend("codex", {
                                commands = { default = require("ai.codex").command() },
                                defaults = { auth_method = "chat-gpt", timeout = 30000 },
                            })
                        end,
                    },
                    http = {
                        game_ai = function()
                            return require("codecompanion.adapters").extend("openai_compatible", {
                                name = "game_ai",
                                formatted_name = "Game Dev AI",
                                env = {
                                    api_key = vim.env.AI_API_KEY and "AI_API_KEY"
                                        or "OPENAI_API_KEY",
                                    url = base,
                                    chat_url = "/chat/completions",
                                    models_endpoint = "/models",
                                },
                                schema = { model = { default = model, choices = { [model] = {} } } },
                            })
                        end,
                    },
                },
                interactions = {
                    chat = {
                        adapter = "codex",
                        keymaps = {
                            game_input = {
                                modes = { n = "gi" },
                                callback = function(chat) require("ai.composer").open(chat, true) end,
                                description = "进入独立消息输入框",
                            },
                            game_switch = {
                                modes = { n = "<Tab>" },
                                callback = function(chat) require("ai.composer").switch(chat) end,
                                description = "切换消息输入框",
                            },
                            game_menu = {
                                modes = { n = "g?" },
                                callback = function(chat) require("ai.composer").menu(chat) end,
                                description = "AI 面板操作菜单",
                            },
                            close = {
                                modes = { n = "<C-c>", i = "<C-c>" },
                                callback = function(chat) require("ai.composer").close(chat) end,
                                description = "收起面板并保留草稿",
                            },
                            game_model = {
                                modes = { n = "gm" },
                                callback = function(chat) require("ai.panel").models(chat) end,
                                description = "选择当前对话模型",
                            },
                            game_history = {
                                modes = { n = "gh" },
                                callback = function(chat) require("ai.panel").history(false, chat) end,
                                description = "恢复当前项目的 Codex 历史",
                            },
                            game_history_all = {
                                modes = { n = "gH" },
                                callback = function(chat) require("ai.panel").history(true, chat) end,
                                description = "恢复全部本地 Codex 历史",
                            },
                            game_new = {
                                modes = { n = "gn" },
                                callback = function() require("ai.codex").new() end,
                                description = "新建 Codex 对话并保留原草稿",
                            },
                        },
                        opts = {
                            system_prompt = function(ctx)
                                return ctx.default_system_prompt
                                    .. "\n你是游戏开发助手，用简体中文回答，代码和技术术语保留原文。"
                                    .. "关注 Unity 生命周期与 GC、Godot 节点和信号、Unreal 反射宏与 UObject 生命周期。"
                                    .. "遵循项目现有风格，在不知道引擎版本时先确认版本。"
                            end,
                        },
                    },
                    inline = { adapter = "game_ai" },
                    background = { adapter = "game_ai" },
                    cmd = { adapter = "game_ai" },
                },
                display = {
                    chat = {
                        intro_message = "Tab 输入 · g? 菜单",
                        window = {
                            position = "right",
                            width = 0.4,
                            opts = {
                                winbar = "%{%v:lua.require('ai.composer').status()%}",
                                number = false,
                                relativenumber = false,
                                cursorcolumn = false,
                            },
                        },
                    },
                },
                opts = { language = "Chinese" },
            }
        end,
        config = function(_, opts)
            require("codecompanion").setup(opts)
            require("ai.composer").setup()
        end,
    },
}
