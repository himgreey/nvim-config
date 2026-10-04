return {
    {
        "mfussenegger/nvim-dap",
        cmd = "GameDebugLoad",
        dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
        keys = {
            {
                "<leader>db",
                function() require("dap").toggle_breakpoint() end,
                desc = "切换断点",
            },
            {
                "<leader>dB",
                function()
                    vim.ui.input({ prompt = "断点条件：" }, function(value)
                        if value then require("dap").set_breakpoint(value) end
                    end)
                end,
                desc = "条件断点",
            },
            {
                "<leader>dc",
                function() require("dap").continue() end,
                desc = "开始/继续调试",
            },
            { "<leader>do", function() require("dap").step_over() end, desc = "单步越过" },
            { "<leader>di", function() require("dap").step_into() end, desc = "单步进入" },
            { "<leader>dO", function() require("dap").step_out() end, desc = "单步跳出" },
            { "<leader>dr", function() require("dap").repl.open() end, desc = "调试 REPL" },
            { "<leader>dl", function() require("dap").run_last() end, desc = "重复上次调试" },
            { "<leader>dt", function() require("dapui").toggle() end, desc = "调试 UI" },
        },
        config = function()
            local dap = require("dap")

            local settings = require("game.config").get()
            local root = function() return require("game.project").detect().root end
            local function find_adapter(custom, name, paths)
                if custom and vim.fn.executable(custom) == 1 then return custom end
                for _, path in ipairs(paths) do
                    if vim.fn.executable(path) == 1 then return path end
                end
                if vim.fn.executable(name) == 1 then return vim.fn.exepath(name) end
            end
            local packages = vim.fn.stdpath("data") .. "/mason/packages/"
            local suffix = vim.fn.has("win32") == 1 and ".exe" or ""
            dap.adapters.coreclr = function(callback)
                local exe = find_adapter(settings.netcoredbg, "netcoredbg", {
                    packages .. "netcoredbg/netcoredbg/netcoredbg" .. suffix,
                    packages .. "netcoredbg/netcoredbg" .. suffix,
                })
                if not exe then
                    vim.notify(
                        "请在 :Mason 安装 netcoredbg 或设置 NETCOREDBG 路径",
                        vim.log.levels.WARN
                    )
                    return
                end
                callback({ type = "executable", command = exe, args = { "--interpreter=vscode" } })
            end
            dap.configurations.cs = {
                {
                    type = "coreclr",
                    name = "启动 .NET DLL（Godot C# / 独立 .NET）",
                    request = "launch",
                    cwd = root,
                    program = function()
                        return vim.fn.input("DLL 路径：", root() .. "/bin/Debug/", "file")
                    end,
                },
                {
                    type = "coreclr",
                    name = "附加 .NET CoreCLR 进程",
                    request = "attach",
                    processId = require("dap.utils").pick_process,
                },
            }
            dap.adapters.godot = {
                type = "server",
                host = settings.godot_host,
                port = settings.godot_dap_port,
            }
            dap.configurations.gdscript = {
                {
                    type = "godot",
                    name = "Godot：运行项目",
                    request = "launch",
                    project = root,
                    launch_game_instance = true,
                    port = settings.godot_debug_port,
                },
            }
            dap.adapters.codelldb = function(callback)
                local exe = find_adapter(settings.codelldb, "codelldb", {
                    packages .. "codelldb/extension/adapter/codelldb" .. suffix,
                })
                if not exe then
                    vim.notify(
                        "请在 :Mason 安装 codelldb 或设置 CODELLDB 路径",
                        vim.log.levels.WARN
                    )
                    return
                end
                callback({
                    type = "server",
                    port = "${port}",
                    executable = {
                        command = exe,
                        args = { "--port", "${port}" },
                        detached = vim.fn.has("win32") == 0,
                    },
                })
            end
            dap.configurations.cpp = {
                {
                    type = "codelldb",
                    name = "启动 C++ 程序",
                    request = "launch",
                    cwd = root,
                    program = function()
                        return vim.fn.input("可执行文件路径：", root() .. "/", "file")
                    end,
                    stopOnEntry = false,
                },
                {
                    type = "codelldb",
                    name = "附加 Unreal/C++ 进程",
                    request = "attach",
                    cwd = root,
                    pid = require("dap.utils").pick_process,
                },
            }
            dap.configurations.c = dap.configurations.cpp
            dap.providers.configs["game-project"] = function(bufnr)
                local p = require("game.project").detect(vim.api.nvim_buf_get_name(bufnr))
                if vim.fs.normalize(vim.fn.getcwd()) == p.root then return {} end
                local ok, configurations =
                    pcall(require("dap.ext.vscode").getconfigs, p.root .. "/.vscode/launch.json")
                if not ok then
                    vim.notify(configurations, vim.log.levels.ERROR)
                    return {}
                end
                return configurations
            end
            -- Unity Editor 使用 Mono/Unity 专用调试器，不能通过 netcoredbg 附加。
            vim.api.nvim_create_user_command("GameDebugLoad", function()
                local path = root() .. "/.vscode/launch.json"
                if vim.fn.filereadable(path) == 0 then
                    vim.notify("未找到 " .. path, vim.log.levels.WARN)
                    return
                end
                local ok, configurations = pcall(require("dap.ext.vscode").getconfigs, path)
                if not ok then
                    vim.notify(configurations, vim.log.levels.ERROR)
                    return
                end
                vim.notify(
                    "调试配置有效，共 "
                        .. #configurations
                        .. " 项；按 <leader>dc 选择运行"
                )
            end, {})
            for name, sign in pairs({
                DapBreakpoint = { "⬤", "DiagnosticSignError" },
                DapBreakpointCondition = { "⬤", "DiagnosticSignWarn" },
                DapLogPoint = { "◆", "DiagnosticSignInfo" },
                DapStopped = { "→", "DiagnosticSignHint", "CursorLine" },
            }) do
                vim.fn.sign_define(
                    name,
                    { text = sign[1], texthl = sign[2], linehl = sign[3] or "" }
                )
            end
            local ui = require("dapui")
            ui.setup({
                icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
                controls = {
                    icons = {
                        pause = "⏸",
                        play = "▶",
                        step_into = "↓",
                        step_over = "→",
                        step_out = "↑",
                        step_back = "←",
                        run_last = "↻",
                        terminate = "⏹",
                    },
                },
                layouts = {
                    {
                        elements = { "scopes", "breakpoints", "stacks", "watches" },
                        size = 40,
                        position = "left",
                    },
                    { elements = { "repl", "console" }, size = 10, position = "bottom" },
                },
            })
            dap.listeners.after.event_initialized["game-ui"] = function() ui.open() end
            dap.listeners.before.event_terminated["game-ui"] = function() ui.close() end
            dap.listeners.before.event_exited["game-ui"] = function() ui.close() end
        end,
    },
}
