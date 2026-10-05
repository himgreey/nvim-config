-- 验证真实 buffer、目录夹具与保存行为；不发送 AI 请求、不安装工具。
local base = vim.fs.normalize(vim.fn.tempname() .. " optimization fixtures")
local original_dir = vim.fs.dir
local original_notify = vim.notify
local ok, err = xpcall(function()
    local function write(path, lines)
        vim.fn.mkdir(vim.fs.dirname(path), "p")
        vim.fn.writefile(lines or {}, path)
    end
    local unity = base .. "/Unity Demo"
    local source = unity .. "/Assets/Lua/player.lua"
    write(unity .. "/ProjectSettings/ProjectVersion.txt", { "m_EditorVersion: 6000.0.1f1" })
    write(source, { "local speed = 1" })
    write(unity .. "/.EmmyLuaUnity/api.lua", { "---@class UnityEngine.GameObject" })
    write(unity .. "/Library/generated.lua")
    write(unity .. "/Packages/package.lua")
    local project = require("game.project")
    project.clear_cache()
    local scans = 0
    vim.fs.dir = function(...)
        scans = scans + 1
        return original_dir(...)
    end
    local found = project.detect(source)
    assert(found.kind == "unity" and found.root == unity)
    assert(scans == 2, "每层目录未合并为单次扫描")
    local previous = scans
    found.root = "mutated"
    assert(
        project.detect(source).root == unity and scans == previous,
        "根目录缓存失效或被调用者修改"
    )
    vim.fs.dir = original_dir
    assert(project.excluded(unity .. "/Library/generated.lua"))
    assert(project.excluded(unity .. "/obj/generated.cs"))
    assert(not project.excluded(source) and not project.excluded(unity .. "/Packages/package.lua"))
    assert(not project.excluded(unity .. "/.EmmyLuaUnity/api.lua"))
    write(unity .. "/project.godot")
    vim.cmd.GameProjectRefresh()
    assert(project.detect(source).kind == "godot", "刷新未识别新项目标记")
    vim.fn.delete(unity .. "/project.godot")
    project.clear_cache()
    local workflow = require("game.lsp")
    local settings = workflow.lua_settings(unity)
    assert(settings.workspace.library[1] == unity .. "/.EmmyLuaUnity")
    assert(vim.tbl_contains(settings.workspace.ignoreDir, "Library"))
    assert(not vim.tbl_contains(settings.workspace.library, vim.env.VIMRUNTIME))
    local nvim = workflow.lua_settings(vim.fn.stdpath("config"))
    assert(nvim.runtime.version == "LuaJIT" and nvim.workspace.library[1] == vim.env.VIMRUNTIME)
    write(unity .. "/.luarc.json", { "{}" })
    assert(workflow.lua_settings(unity) == nil, "项目 Lua 配置未优先")
    vim.fn.delete(unity .. "/.luarc.json")
    require("lazy").load({
        plugins = { "nvim-lspconfig", "nvim-cmp", "conform.nvim", "indent-blankline.nvim" },
    })
    local huge = unity .. "/Assets/Lua/huge.lua"
    write(huge, { "-- " .. ("x"):rep(1024 * 1024 + 1) })
    vim.cmd.edit(vim.fn.fnameescape(huge))
    assert(require("game.buffer").large(0) and vim.b.game_large_file)
    assert(
        vim.wait(1000, function() return vim.bo.syntax == "" end, 10),
        "语法高亮未在 FileType 后关闭"
    )
    assert(
        vim.bo.syntax == "" and vim.bo.indentexpr == "" and not vim.wo.cursorcolumn,
        vim.inspect({
            syntax = vim.bo.syntax,
            indentexpr = vim.bo.indentexpr,
            cursorcolumn = vim.wo.cursorcolumn,
        })
    )
    assert(not require("cmp").get_config().enabled())
    for _, name in ipairs({ "lua_ls", "omnisharp", "clangd", "jsonls", "yamlls", "gdscript" }) do
        local called = false
        vim.lsp.config[name].root_dir(0, function() called = true end)
        assert(not called, "大文件仍启动 LSP: " .. name)
    end
    assert(#vim.lsp.get_clients({ bufnr = 0 }) == 0)
    local saved = vim.fn.tempname() .. ".lua"
    vim.cmd("saveas! " .. vim.fn.fnameescape(saved))
    assert(vim.fn.getfsize(saved) > 1024 * 1024, "大文件无法正常保存")
    vim.fn.delete(saved)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_name(buf, source)
    local lines = {}
    for i = 1, 1600 do
        lines[i] = "local speed" .. i .. " = " .. i
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    assert(not require("game.buffer").large(buf) and require("cmp").get_config().enabled())
    vim.notify = function() end
    assert(require("ai.tools").context(false) == nil, "未阻止超长整文件上下文")
    vim.cmd("normal! ggV2j")
    local context = require("ai.tools").context(true)
    assert(context and context:find("行 1-3", 1, true) and not context:find("speed4 ", 1, true))
    local diagnostics = {}
    for i = 1, 60 do
        diagnostics[i] = { lnum = 0, col = 0, message = "fixture " .. i }
    end
    local ns = vim.api.nvim_create_namespace("OptimizationDiagnostics")
    vim.diagnostic.set(ns, buf, diagnostics)
    context = require("ai.tools").context(true)
    local _, count = context:gsub("诊断 %d+:", "")
    assert(count == 50 and context:find("其余诊断已省略", 1, true))
    vim.diagnostic.set(ns, buf, { { lnum = 0, col = 0, message = ("x"):rep(100000) } })
    assert(#require("ai.tools").context(true) <= 64 * 1024, "诊断绕过上下文大小上限")
    vim.cmd("normal! " .. string.char(27))
    vim.notify = original_notify
    local cmd = vim.cmd.MasonInstall
    local packages
    vim.cmd.MasonInstall = function(opts) packages = opts.args end
    local previous_ei = vim.o.eventignore
    vim.o.eventignore = "FileType"
    vim.bo.filetype = "lua"
    vim.o.eventignore = previous_ei
    workflow.install({}, { "lua_ls", "clangd" })
    vim.cmd.MasonInstall = cmd
    assert(packages and packages[1] == "lua-language-server" and #packages == 1)
    local cs = base .. "/FormatAfterSave.cs"
    local csbuf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(csbuf)
    vim.api.nvim_buf_set_name(csbuf, cs)
    vim.o.eventignore = "FileType"
    vim.bo.filetype = "cs"
    vim.o.eventignore = previous_ei
    vim.api.nvim_buf_set_lines(
        csbuf,
        0,
        -1,
        false,
        { "public class FormatAfterSave{public int Speed;}" }
    )
    vim.cmd.write()
    assert(
        vim.wait(
            10000,
            function()
                return table.concat(vim.fn.readfile(cs), "\n"):find("public int Speed;", 1, true)
                    and #vim.fn.readfile(cs) > 1
            end,
            50
        ),
        "C# 保存后没有异步格式化并写回"
    )
    assert(
        table.concat(vim.fn.readfile(cs), "\n")
            == table.concat(vim.api.nvim_buf_get_lines(csbuf, 0, -1, false), "\n")
    )
    print(
        "PASS: cached roots, engine filters, Lua libraries, large files, bounded AI context, on-demand tools, async C# save"
    )
end, debug.traceback)
vim.fs.dir, vim.notify = original_dir, original_notify
vim.fn.delete(base, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
