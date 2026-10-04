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
                opts = { language = "Chinese" },
            }
        end,
    },
}
