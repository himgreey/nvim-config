-- 真实文件树 + 首页 + AI 阅读/输入区联合布局；不请求模型。
local original_cwd = vim.fn.getcwd()
local root = vim.fn.tempname() .. " layout fixtures"
local ok, err = xpcall(function()
    vim.fn.mkdir(root, "p")
    vim.fn.writefile({ "[application]" }, root .. "/project.godot")
    vim.cmd.cd(vim.fn.fnameescape(root))
    vim.o.columns, vim.o.lines = 140, 42
    local dashboard = Snacks.dashboard.open({ buf = 0, win = 0 })
    require("lazy").load({ plugins = { "nvim-tree.lua", "codecompanion.nvim" } })
    local tree = require("nvim-tree.api")
    local layout, composer = require("ui.layout"), require("ai.composer")
    tree.tree.open()
    vim.api.nvim_set_current_win(dashboard.win)
    local chat = require("ai.codex").new({ root = root })
    chat.acp_connection = {
        is_ready = function() return true end,
        is_connected = function() return true end,
        get_models = function() return { currentModelId = "fixture-model", availableModels = {} } end,
        get_config_options = function() return {} end,
        build_name_map = function() return {} end,
        disconnect = function() end,
        session_id = "layout-fixture",
    }
    chat:update_metadata()
    local function settle()
        layout.request()
        assert(
            vim.wait(1500, function()
                local plan =
                    layout.plan(vim.o.columns, tree.tree.is_visible(), chat.ui:is_visible())
                local tree_win = require("nvim-tree.view").get_winnr()
                return (not tree_win or vim.api.nvim_win_get_width(tree_win) == plan.tree)
                    and (
                        not chat.ui:is_visible()
                        or vim.api.nvim_win_get_width(chat.ui.winnr) == plan.ai
                    )
            end, 10),
            "Sidebars did not reach planned widths"
        )
        vim.api.nvim_exec_autocmds("WinResized", {})
        vim.cmd.redraw()
        vim.wait(30, function() return false end, 10)
    end
    local function dashboard_check()
        assert(
            dashboard._size.width == vim.api.nvim_win_get_width(dashboard.win),
            "Dashboard size was stale"
        )
        local view = vim.api.nvim_win_call(dashboard.win, vim.fn.winsaveview)
        assert(view.leftcol == 0, "Dashboard kept a stale horizontal offset")
        assert(#dashboard.lines <= dashboard._size.height, "Dashboard height overflow")
        for _, line in ipairs(dashboard.lines) do
            assert(
                vim.fn.strwidth(line) <= dashboard._size.width,
                "Dashboard line exceeded actual width"
            )
        end
        local text = table.concat(dashboard.lines, "\n")
        assert(
            text:find("查找文件", 1, true) and text:find("Codex 聊天", 1, true),
            "Dashboard menu was clipped"
        )
        local portrait = require("ui.dashboard").sections(dashboard)[2].text[1]
        local final_row = vim.split(portrait:gsub("\n$", ""), "\n", { plain = true })
        assert(text:find(final_row[#final_row], 1, true), "Portrait feet were clipped")
    end
    for _, size in ipairs({ { 140, 42 }, { 160, 50 }, { 110, 35 }, { 90, 30 }, { 80, 24 } }) do
        vim.o.columns, vim.o.lines = size[1], size[2]
        vim.api.nvim_exec_autocmds("VimResized", {})
        local input = composer.open(chat, false)
        settle()
        local plan = layout.plan(size[1], true, true)
        dashboard_check()
        assert(vim.api.nvim_win_get_width(dashboard.win) >= plan.editor)
        assert(vim.api.nvim_win_get_width(input.win) == plan.ai)
        assert(vim.api.nvim_win_get_height(chat.ui.winnr) >= 8)
        assert(vim.api.nvim_win_get_height(input.win) <= 6)
        for _, win in ipairs({ chat.ui.winnr, input.win }) do
            local width = vim.api.nvim_win_get_width(win)
            local bar = vim.api.nvim_eval_statusline(
                vim.wo[win].winbar,
                { winid = win, use_winbar = true, maxwidth = width }
            ).str
            assert(vim.fn.strwidth(bar) <= width)
            assert(
                bar:find(win == input.win and "[收" or "[", 1, true),
                "Toolbar controls were clipped"
            )
        end
        print(
            ("PASS: combined %dx%d tree=%d editor=%d AI=%d, full portrait/menu and leftcol=0"):format(
                size[1],
                size[2],
                plan.tree,
                vim.api.nvim_win_get_width(dashboard.win),
                plan.ai
            )
        )
    end
    tree.tree.close()
    settle()
    tree.tree.open({ focus = false })
    settle()
    dashboard_check()
    local input = composer.open(chat, false)
    vim.api.nvim_buf_set_lines(input.bufnr, 0, -1, false, { "1", "2", "3", "4", "5", "6" })
    vim.api.nvim_exec_autocmds("TextChanged", { buffer = input.bufnr })
    vim.wait(50, function() return false end, 10)
    assert(vim.api.nvim_win_get_height(input.win) >= 5, "Multiline input did not expand")
    assert(vim.api.nvim_win_get_height(chat.ui.winnr) >= 8)
    composer.close(chat)
    settle()
    dashboard_check()
    tree.tree.close()
    settle()
    dashboard_check()
    assert(vim.api.nvim_win_get_width(dashboard.win) == vim.o.columns)
    assert(vim.v.errmsg == "", vim.v.errmsg)
    print("PASS: sidebar open order, multiline input, collapse restoration and stable redraw")
end, debug.traceback)
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(root, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
