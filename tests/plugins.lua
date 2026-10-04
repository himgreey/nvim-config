-- 在真实 Lazy 环境中加载全部插件，覆盖按需加载配置和 VeryLazy UI。
local ok, err = xpcall(function()
    local config = require("lazy.core.config")
    assert(#config.spec.notifs == 0, vim.inspect(config.spec.notifs))
    local names = {}
    for name in pairs(config.plugins) do
        names[#names + 1] = name
    end
    vim.notify("初始化通知验证", vim.log.levels.INFO)
    local notify, errors = vim.notify, {}
    vim.notify = function(message, level, opts)
        if (level or vim.log.levels.INFO) >= vim.log.levels.ERROR then
            errors[#errors + 1] = tostring(message)
        end
        return notify(message, level, opts)
    end
    require("lazy").load({ plugins = names })
    vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
    -- -c 脚本发生在 VimEnter 之前；显式执行此事件来覆盖 Noice 的延迟 setup。
    vim.api.nvim_exec_autocmds("VimEnter", {})
    vim.wait(350, function() return false end, 50)
    vim.notify = notify
    assert(#errors == 0, table.concat(errors, "\n"))
    assert(vim.v.errmsg == "", vim.v.errmsg)
    assert(not config.plugins["mini.icons"] and not config.plugins["nvim-notify"])
    assert(require("noice.config").options.notify.enabled == false)
    vim.notify("配置通知验证", vim.log.levels.INFO)
    assert(vim.notify == Snacks.notifier.notify, "通知没有统一由 Snacks 管理")
    assert(require("cmp").get_config().sources[1].name == "nvim_lsp")
    assert(require("nvim-autopairs").config.check_ts)
    assert(require("dapui"))
    assert(vim.fn.exists(":MasonToolsInstall") == 2)
    assert(vim.fn.exists(":GameDebugLoad") == 2)
    assert(vim.fn.exists(":NvimTreeToggle") == 2)
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeave" })) do
        if type(autocmd.callback) == "function" then
            local source = debug.getinfo(autocmd.callback, "S").source:gsub("\\", "/")
            assert(
                not source:match("/unity/plugin%.lua$"),
                "Unity 插件仍在退出时调用 pkill"
            )
        end
    end
    assert(type(vim.fn.maparg("<leader>ha", "n", false, true).callback) == "function")
    io.stdout:write(
        "PASS: all plugin configs, UI events, unified notifications and lazy commands\n"
    )
end, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
