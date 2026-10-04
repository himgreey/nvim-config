-- 配置检查：关闭未保存文件、Unity 对应文件切换、临时 buffer 的项目识别。
local base = vim.fs.normalize(vim.fn.tempname() .. " Tests Studio")
local original_cwd = vim.fn.getcwd()
local original_confirm = vim.o.confirm
local failures = {}
local function check(name, fn)
    local ok, err = pcall(fn)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(err) end
end
local function edit(file) vim.cmd("noautocmd edit! " .. vim.fn.fnameescape(file)) end
local function key(lhs)
    local mapping = vim.fn.maparg(lhs, "n", false, true)
    assert(type(mapping.callback) == "function", "快捷键缺少 callback：" .. lhs)
    mapping.callback()
end
vim.fn.mkdir(base .. "/Assets/Scripts", "p")
vim.fn.mkdir(base .. "/ProjectSettings", "p")
local source = base .. "/Assets/Scripts/Player.cs"
local test = base .. "/Assets/Scripts/PlayerTest.cs"
vim.fn.writefile({ "public class Player {}" }, source)
vim.fn.writefile({ "public class PlayerTest {}" }, test)
vim.fn.writefile({ "guid: fixture" }, source .. ".meta")
require("lazy").load({ plugins = { "bufferline.nvim" } })
check("保护未保存文件", function()
    edit(source)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "// unsaved fixture" })
    local buf = vim.api.nvim_get_current_buf()
    vim.o.confirm = false
    local close = require("bufferline.config").options.close_command
    if type(close) == "function" then
        pcall(close, buf)
    else
        pcall(vim.cmd, close:format(buf))
    end
    assert(
        vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified,
        "关闭操作丢弃了未保存内容"
    )
end)
check("测试文件反向切换", function()
    edit(test)
    key("<leader>ua")
    assert(
        vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == source,
        "目录名中的 Tests 影响了文件切换"
    )
end)
check("meta 反向切换", function()
    edit(source .. ".meta")
    key("<leader>um")
    assert(vim.fs.normalize(vim.api.nvim_buf_get_name(0)) == source, "meta 没有切回源文件")
end)
check("保存光标位置", function()
    edit(source)
    vim.api.nvim_buf_set_mark(0, '"', 1, 0, {})
    vim.api.nvim_win_set_cursor(0, { 1, 3 })
    vim.api.nvim_exec_autocmds("BufLeave", { buffer = vim.api.nvim_get_current_buf() })
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    assert(mark[1] == 1 and mark[2] == 3, "离开文件时没有保存光标位置")
end)
check("特殊 buffer 的项目目录", function()
    vim.cmd("enew!")
    vim.bo.buftype = "nofile"
    vim.api.nvim_buf_set_name(0, "[AI audit fixture]")
    vim.b.game_root = base
    local project = require("game.project").detect()
    assert(
        project.kind == "unity" and project.root == base,
        "特殊 buffer 忽略了保存的项目根目录"
    )
end)
vim.o.confirm = original_confirm
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.cmd("enew!")
vim.fn.delete(base, "rf")
if #failures > 0 then
    io.stderr:write(table.concat(failures, "\n") .. "\n")
    vim.cmd("cquit 1")
end
print("PASS: unsaved buffers, Unity counterpart navigation and special-buffer project roots")
vim.cmd("qa!")
