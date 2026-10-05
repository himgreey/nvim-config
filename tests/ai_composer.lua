-- 真实 Chat/UI/submit 流程，替换传输层，绝不调用模型推理。
local original_cwd, original_select = vim.fn.getcwd(), vim.ui.select
local fixtures = vim.fn.tempname() .. " composer fixtures"
local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "codecompanion.nvim" } })
    local composer, codex = require("ai.composer"), require("ai.codex")
    local root = vim.fs.normalize(fixtures)
    vim.fn.mkdir(root, "p")
    vim.fn.writefile({ "[application]" }, root .. "/project.godot")
    vim.fn.writefile({ "extends Node" }, root .. "/player.gd")
    vim.cmd("noautocmd edit " .. vim.fn.fnameescape(root .. "/player.gd"))
    local function new()
        local chat = codex.new({ root = root })
        chat.acp_connection = {
            is_ready = function() return true end,
            is_connected = function() return true end,
            get_models = function()
                return { currentModelId = "fixture-model", availableModels = {} }
            end,
            get_config_options = function() return {} end,
            build_name_map = function() return {} end,
            disconnect = function() end,
            session_id = "fixture-session-" .. chat.id,
        }
        chat:update_metadata()
        return chat
    end
    local chat = new()
    assert(
        vim.wait(1000, function()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.b[vim.api.nvim_win_get_buf(win)].ai_chat_bufnr == chat.bufnr then
                    return true
                end
            end
        end),
        "Input pane did not open automatically"
    )
    local entry = composer.open(chat, false)
    local function text(buf)
        return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    end
    local function write(value)
        vim.api.nvim_buf_set_lines(
            entry.bufnr,
            0,
            -1,
            false,
            vim.split(value, "\n", { plain = true })
        )
    end
    assert(vim.api.nvim_win_get_width(entry.win) == vim.api.nvim_win_get_width(chat.ui.winnr))
    assert(
        vim.api.nvim_win_get_position(entry.win)[1]
            > vim.api.nvim_win_get_position(chat.ui.winnr)[1]
    )
    assert(vim.bo[entry.bufnr].buftype == "nofile" and not vim.bo[entry.bufnr].swapfile)
    for _, key in ipairs({ "<C-s>", "<C-c>", "<C-q>", "<Tab>" }) do
        assert(
            vim.api.nvim_buf_call(entry.bufnr, function() return vim.fn.maparg(key, "i") end) ~= ""
        )
    end
    assert(
        vim.api.nvim_buf_call(entry.bufnr, function() return vim.fn.maparg("<CR>", "i") end) == "",
        "Enter should insert a newline"
    )
    for _, win in ipairs({ chat.ui.winnr, entry.win }) do
        local bar = vim.api.nvim_eval_statusline(
            vim.wo[win].winbar,
            { winid = win, use_winbar = true, maxwidth = 160 }
        ).str
        assert(bar ~= "" and not bar:find("E5108", 1, true))
    end
    composer.open(chat, true)
    assert(composer.current() == chat)
    composer.switch(chat)
    assert(vim.api.nvim_get_current_win() == chat.ui.winnr)
    composer.switch(chat)
    assert(vim.api.nvim_get_current_win() == entry.win)
    vim.cmd.stopinsert()
    print("PASS: automatic bottom input pane, multiline Enter, toolbar rendering and Tab focus")
    local draft = "第一行需求\n第二行需求"
    write(draft)
    composer.close(chat)
    assert(not chat.ui:is_visible() and not entry.win and text(entry.bufnr) == draft)
    codex.open({ root = root })
    entry = composer.open(chat, false)
    assert(text(entry.bufnr) == draft)
    local second = new()
    local second_entry = composer.open(second, false)
    vim.api.nvim_buf_set_lines(second_entry.bufnr, 0, -1, false, { "second chat draft" })
    codex.activate(chat)
    entry = composer.open(chat, false)
    assert(text(entry.bufnr) == draft and text(second_entry.bufnr) == "second chat draft")
    local sent = {}
    chat._submit_acp = function(_, payload)
        sent[#sent + 1] = payload
        chat.current_request = { cancel = function() end }
    end
    local before = text(chat.bufnr)
    chat._game_panel_busy = true
    composer.send(chat)
    chat._game_panel_busy = nil
    assert(#sent == 0 and text(entry.bufnr) == draft and text(chat.bufnr) == before)
    local deny = function() return false end
    chat:add_callback("on_before_submit", deny)
    composer.send(chat)
    assert(#sent == 0 and text(entry.bufnr) == draft and text(chat.bufnr) == before)
    chat:remove_callback("on_before_submit", deny)
    composer.click(chat.bufnr * 10 + 1, 1, "l", "")
    assert(#sent == 1 and text(entry.bufnr) == "")
    local payload = vim.json.encode(sent[1].messages)
    assert(payload:find("第一行需求", 1, true) and payload:find("第二行需求", 1, true))
    write("next unsent draft")
    composer.send(chat)
    assert(
        #sent == 1 and text(entry.bufnr) == "next unsent draft",
        "Busy send discarded the next draft"
    )
    composer.click(chat.bufnr * 10 + 2, 1, "l", "")
    assert(not chat.current_request)
    -- 阅读区或工具链发送不应清除独立输入框里的下一条草稿。
    vim.api.nvim_exec_autocmds(
        "User",
        { pattern = "CodeCompanionChatSubmitted", data = { bufnr = chat.bufnr } }
    )
    assert(text(entry.bufnr) == "next unsent draft")
    print(
        "PASS: per-chat drafts, hide/reopen, rejected send rollback, multiline submit and busy preservation"
    )
    local selected
    vim.ui.select = function(items, _, callback) selected = { items = items, callback = callback } end
    composer.click(chat.bufnr * 10 + 6, 1, "l", "")
    assert(selected and vim.tbl_contains(selected.items, "已打开的对话"))
    selected.callback("已打开的对话")
    assert(#selected.items == 2)
    selected.callback(second)
    assert(
        require("codecompanion").last_chat() == second
            and text(second_entry.bufnr) == "second chat draft"
    )
    composer.click(second.bufnr * 10 + 3, 1, "l", "")
    assert(not second.ui:is_visible() and not second_entry.win)
    assert(vim.v.errmsg == "", vim.v.errmsg)
    print("PASS: clickable menu, open-chat switch and hide button")
    -- 不同终端尺寸下，输入框保持在阅读区下方且窗口不泄漏。
    for _, size in ipairs({ { 160, 50 }, { 90, 30 }, { 80, 24 } }) do
        vim.o.columns, vim.o.lines = size[1], size[2]
        codex.activate(chat)
        entry = composer.open(chat, false)
        assert(vim.api.nvim_win_get_height(chat.ui.winnr) >= 4)
        assert(vim.api.nvim_win_get_height(entry.win) >= 3)
        assert(vim.api.nvim_win_get_width(entry.win) == vim.api.nvim_win_get_width(chat.ui.winnr))
        composer.close(chat)
        assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "Panel left an orphan window")
    end
    print("PASS: 160x50 / 90x30 / 80x24 layouts and window cleanup")
    codex.activate(chat)
    entry = composer.open(chat, false)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= entry.win and win ~= chat.ui.winnr then vim.api.nvim_win_close(win, true) end
    end
    composer.close(chat)
    assert(#vim.api.nvim_tabpage_list_wins(0) == 1 and not chat.ui:is_visible())
    assert(vim.bo.buftype == "" and text(entry.bufnr) == "next unsent draft")
    assert(vim.v.errmsg == "", vim.v.errmsg)
    print("PASS: hiding the last AI windows returns to an editor and preserves input")
end, debug.traceback)
vim.ui.select = original_select
vim.cmd.tcd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(fixtures, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
