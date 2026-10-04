-- 检查真实 Lazy Git 分支解析和插件远程地址，覆盖加载测试无法发现的更新错误。
local ok, err = xpcall(function()
    local plugins = require("lazy.core.config").plugins
    local git = require("lazy.manage.git")
    local failures = {}
    local lock = vim.json.decode(
        table.concat(vim.fn.readfile(require("lazy.core.config").options.lockfile), "\n")
    )
    for _, name in ipairs({ "codecompanion.nvim", "mason.nvim", "mason-lspconfig.nvim" }) do
        local plugin = assert(plugins[name])
        assert(
            lock[name] and lock[name].branch and lock[name].commit,
            "invalid lock entry: " .. name
        )
        for _, task in ipairs(plugin._.tasks or {}) do
            assert(not task:has_errors(), name .. ": " .. task:output(vim.log.levels.ERROR))
        end
        local target_ok, target = pcall(git.get_target, plugin)
        if not target_ok then failures[#failures + 1] = name .. ": " .. target end
        local origin = vim.system(
            { "git", "-C", plugin.dir, "config", "--get", "remote.origin.url" },
            { text = true }
        ):wait()
        if vim.trim(origin.stdout or "") ~= plugin.url then
            failures[#failures + 1] = name .. ": Origin has changed"
        end
        if target_ok then
            assert(target.branch and target.commit, "missing Git target: " .. name)
        end
    end
    assert(#failures == 0, table.concat(failures, "\n"))
    print("PASS: Lazy Git targets and origins for all three plugins")
end, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
