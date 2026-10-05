-- 真实 ACP 模型/历史接口 + 受控会话回放；不发送推理请求或打印历史内容。
local original_select, original_notify = vim.ui.select, vim.notify
local original_cwd = vim.fn.getcwd()
local fixtures = vim.fn.tempname() .. " ai panel fixtures"
local connections = {}
local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "codecompanion.nvim" } })
    local panel, codex = require("ai.panel"), require("ai.codex")
    local notices, submitted, restored = {}, 0, 0
    vim.notify = function(message) notices[#notices + 1] = message end
    vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatSubmitted",
        callback = function() submitted = submitted + 1 end,
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionACPChatRestored",
        callback = function() restored = restored + 1 end,
    })
    local root = vim.fs.normalize(fixtures .. "/Unity")
    vim.fn.mkdir(root .. "/Assets/Lua", "p")
    vim.fn.mkdir(root .. "/ProjectSettings", "p")
    vim.fn.writefile({ "local draft = 'keep me'" }, root .. "/Assets/Lua/test.lua")
    vim.cmd("noautocmd edit " .. vim.fn.fnameescape(root .. "/Assets/Lua/test.lua"))
    codex.add(false)
    local chat = assert(require("codecompanion").last_chat())
    assert(
        vim.wait(
            30000,
            function() return chat.acp_connection and chat.acp_connection:is_connected() end,
            50
        ),
        "Real ACP chat did not connect"
    )
    local real = chat.acp_connection
    connections[#connections + 1] = real
    local draft = table.concat(vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false), "\n")
    assert(real:can_list_sessions() and real:can_load_session())
    local models = assert(real:get_models())
    assert(#models.availableModels > 0 and type(models.currentModelId) == "string")
    assert(
        real:set_model(models.currentModelId),
        "Real model setter did not acknowledge current model"
    )
    chat:update_metadata()
    local sessions = panel.sessions(real)
    assert(#sessions > 0, "Existing local Codex sessions were not listed")
    print(
        "PASS: real ACP model catalog ("
            .. #models.availableModels
            .. "), model setter and local history ("
            .. #sessions
            .. ")"
    )
    local winbar = vim.api.nvim_eval_statusline(vim.wo.winbar, {
        winid = vim.api.nvim_get_current_win(),
        use_winbar = true,
        maxwidth = 160,
    }).str
    assert(winbar:find(models.currentModelId, 1, true) and winbar:find("模", 1, true))
    for _, key in ipairs({ "gm", "gh", "gH", "gn" }) do
        assert(vim.fn.maparg(key, "n", false, true).buffer == 1, "Missing panel shortcut: " .. key)
    end
    for _, key in ipairs({ " am", " ah", " aH", " an" }) do
        assert(vim.fn.maparg(key, "n") ~= "", "Missing global shortcut: " .. key)
    end
    local function lines()
        return table.concat(vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false), "\n")
    end
    local picker
    vim.ui.select = function(items, opts, callback)
        picker = { items = items, opts = opts, callback = callback }
    end
    panel.models(chat)
    assert(vim.wait(1000, function() return picker ~= nil end))
    assert(
        #picker.items == #models.availableModels
            and picker.opts.prompt:find(models.currentModelId, 1, true)
    )
    picker.callback(nil)
    assert(lines() == draft, "Canceling model selection changed the draft")
    -- 选择另一个真实模型并恢复，测试不产生模型推理费用。
    local next_model = models.availableModels[#models.availableModels]
    picker.callback(next_model)
    assert(vim.wait(10000, function() return not chat._game_panel_busy end))
    assert(real:get_models().currentModelId == next_model.modelId)
    assert(lines() == draft, "Changing models changed the draft")
    assert(real:set_model(models.currentModelId))
    chat:update_metadata()
    picker = nil
    panel.history(true, chat)
    assert(vim.wait(20000, function() return picker ~= nil end), "All history picker did not open")
    assert(#picker.items > 0 and type(picker.opts.format_item(picker.items[1])) == "string")
    picker.callback(nil)
    assert(lines() == draft and require("codecompanion").last_chat() == chat)
    chat.current_request = {}
    picker = nil
    panel.models(chat)
    assert(picker == nil, "Model selector opened while generation was busy")
    chat.current_request = nil
    print(
        "PASS: live model winbar, shortcuts, real picker/model switch, cancel preservation and busy guard"
    )
    local existing
    -- 最新会话可能就是运行本测试的 Codex 桌面对话，优先验证较早的闲置会话。
    for i = #sessions, 1, -1 do
        local session = sessions[i]
        if session.cwd and vim.fn.isdirectory(session.cwd) == 1 then
            existing = session
            break
        end
    end
    assert(existing, "No existing session with an accessible cwd")
    local history_chat = assert(panel.resume(existing, chat))
    assert(
        vim.wait(30000, function() return not history_chat._game_panel_busy end, 50),
        "Real history restore timed out"
    )
    if history_chat.acp_connection then
        connections[#connections + 1] = history_chat.acp_connection
    end
    assert(
        vim.api.nvim_buf_is_loaded(history_chat.bufnr),
        "Real history load failed: " .. tostring(notices[#notices])
    )
    assert(history_chat.acp_connection.session_id == existing.sessionId and restored == 1)
    assert(vim.fs.normalize(vim.fn.getcwd()) == vim.fs.normalize(existing.cwd))
    assert(lines() == draft and submitted == 0)
    local history_messages =
        table.concat(vim.api.nvim_buf_get_lines(history_chat.bufnr, 0, -1, false), "\n")
    assert(
        #history_messages > 0 and history_chat.title ~= nil,
        "Real history messages/title were not restored"
    )
    print("PASS: real existing Codex session/load, matching session ID/cwd and no automatic prompt")
    codex.activate(chat)
    restored = 0
    local child = {
        sessionId = "child",
        cwd = root:upper():gsub("/", "\\") .. "\\Assets\\Lua",
        updatedAt = "2026-10-05T10:00:00Z",
    }
    local parent = { sessionId = "root", cwd = root, updatedAt = "2026-10-04T10:00:00Z" }
    local outside =
        { sessionId = "outside", cwd = root .. "-other", updatedAt = "2026-10-03T10:00:00Z" }
    local calls = 0
    local paged = {
        send_rpc_request = function(_, method, params)
            assert(method == "session/list" and params.cwd == nil)
            calls = calls + 1
            if not params.cursor then return { sessions = {}, nextCursor = "second" } end
            if params.cursor == "second" then
                return { sessions = { parent, outside }, nextCursor = "third" }
            end
            return { sessions = { child, parent } }
        end,
    }
    local filtered = panel.sessions(paged, root)
    assert(calls == 3 and #filtered == 2 and filtered[1].sessionId == "child")
    assert(#panel.sessions(paged) == 3)
    local loop = { send_rpc_request = function() return { sessions = {}, nextCursor = "loop" } end }
    assert(not pcall(panel.sessions, loop), "Repeated history cursor was not detected")
    print(
        "PASS: empty-page pagination, deduplication, descendant cwd, Windows casing and sibling exclusion"
    )
    -- 使用插件的真实 Chat/UI/render，回放受控 ACP 消息，验证 ID 与 cwd。
    local factory = codex.new
    local loaded_cwd
    local fail = false
    codex.new = function(project, cwd)
        local new_chat = factory(project, cwd)
        local fake = {
            is_connected = function() return true end,
            is_ready = function() return true end,
            disconnect = function() end,
            session_id = "new-empty",
            get_models = function() return models end,
            get_config_options = function() return {} end,
            build_name_map = function() return {} end,
            load_session = function(self, id, opts)
                loaded_cwd = vim.fs.normalize(vim.fn.getcwd())
                self.session_id = fail and "fallback-new-id" or id
                opts.on_session_update({
                    sessionUpdate = "user_message_chunk",
                    content = { type = "text", text = "fixture question" },
                })
                opts.on_session_update({
                    sessionUpdate = "agent_message_chunk",
                    content = { type = "text", text = "fixture answer" },
                })
                return true
            end,
        }
        new_chat.acp_connection = fake
        return new_chat
    end
    local selected =
        { sessionId = "fixture-history-id", cwd = root .. "/Assets/Lua", title = "fixture history" }
    local resumed = assert(panel.resume(selected, chat))
    assert(resumed.acp_connection.session_id == selected.sessionId and restored == 1)
    assert(loaded_cwd == selected.cwd and vim.b[resumed.bufnr].game_root == root)
    local replay = table.concat(vim.api.nvim_buf_get_lines(resumed.bufnr, 0, -1, false), "\n")
    assert(replay:find("fixture question", 1, true) and replay:find("fixture answer", 1, true))
    assert(lines() == draft, "Resuming history overwrote the old draft")
    assert(
        panel.resume(selected, chat) == resumed and restored == 1,
        "An already open session was loaded twice"
    )
    fail = true
    local failed =
        assert(panel.resume({ sessionId = "fixture-failure-id", cwd = selected.cwd }, chat))
    assert(not vim.api.nvim_buf_is_loaded(failed.bufnr) and restored == 1)
    assert(require("codecompanion").last_chat() == chat and lines() == draft)
    chat.ui:hide()
    vim.cmd("noautocmd edit " .. vim.fn.fnameescape(root .. "/Assets/Lua/test.lua"))
    assert(codex.open() == chat, "Failed restore lost the original project chat cache")
    codex.new = factory
    assert(submitted == 0, "An AI action submitted a prompt automatically")
    chat._game_panel_busy = true
    chat:submit()
    assert(
        submitted == 0 and lines() == draft,
        "Submitting while a panel operation was running changed the draft"
    )
    chat._game_panel_busy = nil
    assert(vim.v.errmsg == "", vim.v.errmsg)
    print(
        "PASS: real chat history rendering, session identity, original cwd, draft preservation and failed-load rollback"
    )
end, debug.traceback)
for _, conn in ipairs(connections) do
    if conn._state and conn._state.handle then conn:disconnect() end
end
vim.ui.select, vim.notify = original_select, original_notify
vim.cmd.tcd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(fixtures, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
