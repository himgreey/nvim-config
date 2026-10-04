-- 运行：nvim --headless -u NONE -i NONE -l tests/game_dev.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local base = vim.fn.tempname() .. " game fixtures"
local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines or {}, path)
end
local function check()
    for _, file in ipairs(vim.fn.globpath(vim.fn.getcwd(), "lua/**/*.lua", false, true)) do
        assert(loadfile(file), "Lua 语法错误：" .. file)
    end
    assert(loadfile("init.lua"))
    local p = require("game.project")
    write(
        base .. "/Unity Game/ProjectSettings/ProjectVersion.txt",
        { "m_EditorVersion: 6000.0.1f1" }
    )
    write(base .. "/Unity Game/Assets/Scripts/Player.cs")
    write(base .. "/Godot Game/project.godot")
    write(base .. "/Godot Game/scripts/player.gd")
    write(base .. "/Unreal Game/MyGame.uproject", { "{}" })
    write(base .. "/Unreal Game/Source/MyGame/Player.cpp")
    write(base .. "/Dotnet Game/MyGame.sln")
    write(base .. "/Dotnet Game/src/Player.cs")
    for _, case in ipairs({
        { "unity", "Unity Game", "Assets/Scripts/Player.cs" },
        { "godot", "Godot Game", "scripts/player.gd" },
        { "unreal", "Unreal Game", "Source/MyGame/Player.cpp" },
        { "generic", "Dotnet Game", "src/Player.cs" },
    }) do
        local expected = vim.fs.normalize(base .. "/" .. case[2])
        local found = p.detect(expected .. "/" .. case[3])
        assert(found.kind == case[1], vim.inspect(found))
        assert(found.root == expected, vim.inspect(found))
    end
    local player = base .. "/Unity Game/Assets/Scripts/Player.cs"
    vim.api.nvim_buf_set_name(0, player)
    local search = p.picker_opts()
    assert(vim.tbl_contains(search.exclude, "**/Library/**"))
    assert(not vim.tbl_contains(search.exclude, "**/Packages/**"))
    assert(not search.ignored)
    assert(p.picker_opts(true).ignored)
    vim.bo.buftype = "nofile"
    vim.b.game_root = base .. "/Godot Game"
    assert(p.detect("term://test").kind == "godot")
    vim.bo.buftype = ""
    vim.b.game_root = nil
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "public class Player {}", "// line two" })
    vim.bo.filetype = "cs"
    vim.diagnostic.set(vim.api.nvim_create_namespace("GameDevTest"), 0, {
        {
            lnum = 0,
            col = 0,
            message = "fixture diagnostic",
            severity = vim.diagnostic.severity.WARN,
        },
    })
    local context = require("ai.tools").context(false)
    assert(context:find("Assets/Scripts/Player.cs", 1, true))
    assert(context:find("fixture diagnostic", 1, true))
    assert(context:find("public class Player", 1, true))
    require("config.options")
    require("game.filetypes").setup()
    for ext, ft in pairs({
        gd = "gdscript",
        gdshader = "gdshader",
        asmdef = "json",
        prefab = "yaml",
        uproject = "json",
        uplugin = "json",
        usf = "hlsl",
        ush = "hlsl",
        tscn = "godot_resource",
    }) do
        assert(vim.filetype.match({ filename = "test." .. ext }) == ft, ext)
    end
    require("config.autocmds")
    vim.bo.filetype = "gdscript"
    assert(not vim.bo.expandtab and vim.bo.tabstop == 4)
    vim.bo.filetype = "cs"
    assert(vim.bo.expandtab and vim.bo.shiftwidth == 4)
    assert(vim.fn.filereadable(base .. "/Unity Game/.ignore") == 0)
    print("PASS: Lua syntax, engine roots, searches, AI context, filetypes and indentation")
end
local ok, err = xpcall(check, debug.traceback)
-- 只清理本次创建的独立临时夹具。
vim.fn.delete(base, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
