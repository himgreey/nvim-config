local M = {}
local project = require("game.project")
local config = require("game.config")
local terminal = require("game.terminal")

local function warn(message) vim.notify(message, vim.log.levels.WARN) end

function M.executable(kind, root)
    local opts = config.get()
    if kind == "godot" then
        if opts.godot and opts.godot ~= "" then return opts.godot end
        for _, name in ipairs({ "godot", "godot4", "godot-mono" }) do
            if vim.fn.executable(name) == 1 then return name end
        end
        warn("请设置 GODOT_BIN 为 Godot 可执行文件完整路径")
    elseif kind == "unity" then
        if opts.unity and opts.unity ~= "" then return opts.unity end
        local version_file = vim.fs.joinpath(root, "ProjectSettings", "ProjectVersion.txt")
        if vim.fn.filereadable(version_file) == 1 and vim.env.ProgramFiles then
            local version =
                table.concat(vim.fn.readfile(version_file), "\n"):match("m_EditorVersion:%s*(%S+)")
            if version then
                local candidate = vim.fs.joinpath(
                    vim.env.ProgramFiles,
                    "Unity",
                    "Hub",
                    "Editor",
                    version,
                    "Editor",
                    "Unity.exe"
                )
                if vim.fn.executable(candidate) == 1 then return candidate end
            end
        end
        warn("请设置 UNITY_EDITOR 为项目对应版本的 Unity.exe 路径")
    elseif kind == "unreal" then
        if opts.unreal and opts.unreal ~= "" then
            local exe = vim.fn.has("win32") == 1 and "Engine/Binaries/Win64/UnrealEditor.exe"
                or "Engine/Binaries/Linux/UnrealEditor"
            return vim.fs.joinpath(opts.unreal, exe)
        end
        warn("请设置 UNREAL_ENGINE_PATH 为包含 Engine 目录的虚幻引擎安装根目录")
    end
end

local function save() vim.cmd("wall") end

function M.run(editor)
    local p = project.detect()
    if p.kind == "generic" then
        warn("当前文件不在 Unity、Godot 或 Unreal 项目中")
        return
    end
    local exe = M.executable(p.kind, p.root)
    if not exe then return end
    save()
    local argv = { exe }
    if p.kind == "godot" then
        vim.list_extend(argv, { "--path", p.root })
        if editor then argv[#argv + 1] = "--editor" end
    elseif p.kind == "unity" then
        vim.list_extend(argv, { "-projectPath", p.root })
    else
        argv[#argv + 1] = p.project
        if not editor then argv[#argv + 1] = "-game" end
    end
    terminal.open(argv, p.root, p.root .. (editor and ":editor" or ":run"))
end

local function dotnet_build(p)
    local solutions = project.files(p.root, ".slnx")
    vim.list_extend(solutions, project.files(p.root, ".sln"))
    if #solutions == 0 then solutions = project.files(p.root, ".csproj") end
    if #solutions == 0 then
        warn("未找到 .sln/.slnx/.csproj；Unity 请先在编辑器中重新生成项目文件")
        return
    end
    local function build(file)
        if not file then return end
        save()
        terminal.open({ "dotnet", "build", file }, p.root, p.root .. ":build")
    end
    if #solutions == 1 then
        build(solutions[1])
    else
        vim.ui.select(solutions, { prompt = "选择 .NET 构建项目" }, build)
    end
end
M.dotnet_build = function() dotnet_build(project.detect()) end

function M.build()
    local p = project.detect()
    if p.kind == "unity" or p.kind == "generic" then
        dotnet_build(p)
    elseif p.kind == "godot" then
        M.run(true)
    elseif p.kind == "unreal" then
        local engine = config.get().unreal
        if not engine or engine == "" then
            M.executable("unreal", p.root)
            return
        end
        local script = vim.fs.joinpath(
            engine,
            "Engine",
            "Build",
            "BatchFiles",
            vim.fn.has("win32") == 1 and "Build.bat" or "Linux/Build.sh"
        )
        local targets =
            vim.fn.globpath(vim.fs.joinpath(p.root, "Source"), "*.Target.cs", false, true)
        if #targets == 0 then
            warn("未找到 Source/*.Target.cs（Blueprint 项目没有 C++ 构建目标）")
            return
        end
        vim.ui.select(targets, {
            prompt = "选择 Unreal 构建目标",
            format_item = function(file) return vim.fs.basename(file):gsub("%.Target%.cs$", "") end,
        }, function(file)
            if not file then return end
            save()
            terminal.open({
                script,
                vim.fs.basename(file):gsub("%.Target%.cs$", ""),
                vim.fn.has("win32") == 1 and "Win64" or "Linux",
                "Development",
                "-Project=" .. p.project,
                "-WaitMutex",
            }, p.root, p.root .. ":build")
        end)
    end
end

function M.test()
    local p = project.detect()
    if p.kind == "unity" then
        local exe = M.executable("unity", p.root)
        if not exe then return end
        vim.ui.select(
            { "EditMode", "PlayMode" },
            { prompt = "Unity Test Framework（先关闭同项目编辑器）" },
            function(mode)
                if not mode then return end
                save()
                terminal.open({
                    exe,
                    "-batchmode",
                    "-projectPath",
                    p.root,
                    "-runTests",
                    "-testPlatform",
                    mode,
                    "-testResults",
                    vim.fs.joinpath(vim.fn.stdpath("state"), "unity-test-results.xml"),
                    "-logFile",
                    "-",
                }, p.root, p.root .. ":test")
            end
        )
    elseif p.kind == "generic" then
        save()
        terminal.open({ "dotnet", "test" }, p.root, p.root .. ":test")
    else
        warn("Godot/Unreal 测试依赖项目测试框架；请使用项目自身的测试命令")
    end
end

function M.info()
    local p = project.detect()
    vim.notify("项目类型：" .. p.kind .. "\n项目目录：" .. p.root, vim.log.levels.INFO)
end

function M.setup()
    for name, fn in pairs({
        GameRun = function() M.run(false) end,
        GameEditor = function() M.run(true) end,
        GameBuild = M.build,
        GameTest = M.test,
        GameInfo = M.info,
    }) do
        vim.api.nvim_create_user_command(name, fn, {})
    end
end
return M
