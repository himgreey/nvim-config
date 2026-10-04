-- 原生首页渲染检查，覆盖双栏与较小的终端，不启动引擎或发送 AI 请求。
local base = vim.fn.tempname() .. " dashboard projects"
local original_oldfiles = vim.v.oldfiles
local ok, err = xpcall(function()
    local files = {}
    for _, name in ipairs({ "Godot Demo", "Unity Demo", "Unreal Demo" }) do
        local root = base .. "/" .. name
        vim.fn.mkdir(root, "p")
        if name:find("Godot") then
            vim.fn.writefile({}, root .. "/project.godot")
        elseif name:find("Unity") then
            vim.fn.mkdir(root .. "/Assets", "p")
            vim.fn.mkdir(root .. "/ProjectSettings", "p")
        else
            vim.fn.writefile({ "{}" }, root .. "/Demo.uproject")
        end
        local file = root .. "/player.txt"
        vim.fn.writefile({ "dashboard fixture" }, file)
        files[#files + 1] = file
    end
    vim.v.oldfiles = files
    local dashboard
    for _, case in ipairs({
        { 160, 62, 2 },
        { 140, 40, 2 },
        { 90, 42, 2 },
        { 80, 42, 1 },
        { 80, 24, 1 },
    }) do
        if dashboard then vim.api.nvim_buf_delete(dashboard.buf, { force = true }) end
        vim.o.columns, vim.o.lines = case[1], case[2]
        dashboard = Snacks.dashboard.open({ buf = 0, win = 0 })
        assert(#dashboard.panes == case[3], "Wrong pane count for " .. case[1])
        assert(
            #dashboard.lines <= dashboard._size.height,
            ("首页高度溢出 %dx%d: %d > %d"):format(
                case[1],
                case[2],
                #dashboard.lines,
                dashboard._size.height
            )
        )
        local text = table.concat(dashboard.lines, "\n")
        assert(text:find("REI AYANAMI", 1, true) and text:find("Codex 聊天", 1, true))
        local sections = require("ui.dashboard").sections(dashboard)
        local portrait = sections[2].text[1]
        local art = require("ui.art.rei")
        local matched = false
        for _, full_body in pairs(art) do
            local lines = vim.split(full_body:gsub("\n$", ""), "\n", { plain = true })
            local last = lines[#lines]
            if portrait:find(last, 1, true) then
                assert(text:find(last, 1, true), "人物下半身未完整渲染")
                matched = true
                break
            end
        end
        assert(matched, "首页没有使用完整人物素材")
        for _, line in ipairs(dashboard.lines) do
            assert(vim.fn.strdisplaywidth(line) <= dashboard._size.width, "首页宽度溢出")
        end
        for _, key in ipairs({ "f", "n", "p", "g", "r", "c", "a", "l", "q" }) do
            assert(
                vim.fn.maparg(key, "n", false, true).buffer == 1,
                "Missing dashboard key: " .. key
            )
        end
        assert(vim.v.errmsg == "", vim.v.errmsg)
        print(
            ("PASS: dashboard %dx%d, %d panes, %d rows"):format(
                case[1],
                case[2],
                #dashboard.panes,
                #dashboard.lines
            )
        )
    end
    assert(vim.api.nvim_get_hl(0, { name = "ReiPortrait" }).fg)
    assert(
        vim.api.nvim_get_hl(0, { name = "SnacksDashboardNormal" }).bg == nil,
        "首页背景不透明"
    )
    vim.cmd.colorscheme("catppuccin")
    assert(
        vim.api.nvim_get_hl(0, { name = "SnacksDashboardNormal" }).bg == nil,
        "切换主题后透明失效"
    )
end, debug.traceback)
vim.v.oldfiles = original_oldfiles
vim.fn.delete(base, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
