-- 使用真实 Ctrl+n，检查定位功能和阻塞性的 Git 查询回归。
local root = vim.fn.tempname() .. " tree navigation"
local original_cwd = vim.fn.getcwd()
local git_utils, original_get_toplevel
local ok, err = xpcall(function()
    local first = root .. "/first/src/nested/player.txt"
    local second = root .. "/second/scripts/player.txt"
    for _, path in ipairs({ first, second }) do
        vim.fn.mkdir(vim.fs.dirname(path), "p")
        vim.fn.writefile({ "navigation fixture" }, path)
    end
    require("lazy").load({ plugins = { "nvim-tree.lua" } })
    local api = require("nvim-tree.api")
    git_utils = require("nvim-tree.git.utils")
    original_get_toplevel = git_utils.get_toplevel
    local git_queries = 0
    git_utils.get_toplevel = function(...)
        git_queries = git_queries + 1
        return original_get_toplevel(...)
    end
    local function toggle()
        vim.cmd("normal " .. vim.api.nvim_replace_termcodes("<C-n>", true, false, true))
    end
    local function edit(path) vim.cmd.edit(vim.fn.fnameescape(path)) end
    local function located(path)
        return vim.wait(1000, function()
            local node = api.tree.get_node_under_cursor()
            return node and vim.uv.fs_realpath(node.absolute_path) == vim.uv.fs_realpath(path)
        end, 10)
    end
    vim.cmd.cd(vim.fn.fnameescape(root .. "/first"))
    edit(first)
    toggle()
    assert(located(first), "首次打开未展开并定位当前文件")
    toggle()
    edit(second)
    toggle()
    assert(located(second), "跨目录重新打开未定位当前文件")
    vim.cmd("wincmd p")
    edit(first)
    assert(located(first), "文件树没有跟随当前文件")
    assert(
        git_queries == 0,
        "文件树打开触发了 " .. git_queries .. " 次同步 Git 仓库查询"
    )
    api.tree.close()
    print("PASS: Ctrl+n reveals files, follows buffers, and performs no synchronous Git queries")
end, debug.traceback)
if original_get_toplevel then git_utils.get_toplevel = original_get_toplevel end
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(root, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
