local M = {}
function M.check()
    local health = vim.health
    health.start("游戏开发环境")
    local p = require("game.project").detect()
    health.info("当前项目：" .. p.kind .. "，" .. p.root)
    for _, name in ipairs({
        "git",
        "rg",
        "dotnet",
        "clangd",
        "curl",
        "tree-sitter",
        "python",
        "gdformat",
        "clang-format",
        "node",
        "codex",
    }) do
        if vim.fn.executable(name) == 1 then
            health.ok(name .. ": " .. vim.fn.exepath(name))
        else
            health.warn(name .. " 未安装或不在 PATH；对应功能需要安装此工具")
        end
    end
    local cfg = require("game.config").get()
    health.info(
        "Godot LSP/DAP："
            .. cfg.godot_host
            .. ":"
            .. cfg.godot_lsp_port
            .. "/"
            .. cfg.godot_dap_port
    )
    if p.kind == "unreal" then
        if vim.fn.filereadable(p.root .. "/compile_commands.json") == 1 then
            health.ok("找到 compile_commands.json")
        else
            health.warn(
                "Unreal 项目根目录缺少 compile_commands.json；clangd 的宏和头文件解析需要正确的编译数据库"
            )
        end
    end
    local command = require("ai.codex").command()
    if vim.fn.executable(command[1]) == 1 then
        health.ok("Codex ACP：" .. table.concat(command, " "))
    else
        health.warn("Codex ACP 未安装；参见 README 的安装命令，或设置 CODEX_ACP_BIN")
    end
    health.info(
        "默认 AI 使用 Codex 的 ChatGPT 登录；在终端运行 codex login status 检查登录状态"
    )
    if vim.env.AI_API_KEY or vim.env.OPENAI_API_KEY then
        health.ok("可选 HTTP API：已检测到 key 环境变量（不显示密钥）")
        health.info("HTTP 模型：" .. (vim.env.AI_MODEL or "gpt-4.1"))
    else
        health.info("可选 HTTP API 未配置；Codex 聊天无需 API key")
    end
end
return M
