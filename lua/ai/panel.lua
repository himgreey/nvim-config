local M = {}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Codex" })
end

local function valid(chat) return chat and vim.api.nvim_buf_is_loaded(chat.bufnr) end

local function available(chat)
    if not valid(chat) then return false end
    if chat.current_request or chat._game_panel_busy then
        notify("请等待当前 Codex 操作完成，或先按 q 停止生成", vim.log.levels.WARN)
        return false
    end
    return true
end

local function resolve(chat)
    return chat or require("ai.composer").current() or require("ai.codex").open()
end

-- 等待插件自己的异步握手，避免并发初始化同一个 ACP 连接。
local function connection(chat)
    local async = require("codecompanion.utils.async")
    local deadline = vim.uv.hrtime() + 30e9
    while valid(chat) and vim.uv.hrtime() < deadline do
        local conn = chat.acp_connection
        if conn and conn:is_connected() then return conn end
        async.wait(function(done) vim.defer_fn(done, 50) end)
    end
    error("Codex 连接尚未就绪；请检查 :checkhealth game 和 :CodeCompanionLogs", 0)
end

local function run(chat, task, on_error)
    if not available(chat) then return end
    if chat.adapter.type ~= "acp" or chat.adapter.name ~= "codex" then
        notify("此操作需要 Codex 聊天，请用 空格 a c 打开", vim.log.levels.WARN)
        return
    end
    chat._game_panel_busy = true
    require("codecompanion.utils.async").sync(function()
        local ok, err = xpcall(function() task(connection(chat)) end, tostring)
        chat._game_panel_busy = nil
        if not ok then
            if on_error then on_error() end
            notify(err, vim.log.levels.ERROR)
        end
    end)()
end

function M.status()
    local metadata = (_G.codecompanion_chat_metadata or {})[vim.api.nvim_get_current_buf()]
    local adapter = metadata and metadata.adapter or {}
    local model = tostring(adapter.model or "连接中…"):gsub("[\r\n]", " "):gsub("%%", "%%%%")
    return " "
        .. (adapter.name or "Codex")
        .. " · "
        .. model
        .. " %=%<gm 模型  gh 项目历史  gH 全部  gn 新建  ? 帮助 "
end

function M.models(chat)
    chat = resolve(chat)
    if chat and chat.adapter.type == "http" then
        return require("codecompanion.interactions.chat.keymaps.change_adapter").select_model(chat)
    end
    run(chat, function(conn)
        local models = conn:get_models()
        if not models or #(models.availableModels or {}) == 0 then
            return notify(
                "Codex 未返回可选模型，请检查登录状态和桥接版本",
                vim.log.levels.WARN
            )
        end
        vim.schedule(function()
            if not valid(chat) then return end
            vim.ui.select(models.availableModels, {
                prompt = "Codex 模型（当前：" .. (models.currentModelId or "默认") .. "）",
                format_item = function(item)
                    return (item.modelId == models.currentModelId and "✓ " or "  ")
                        .. (item.name or item.modelId)
                        .. " ["
                        .. item.modelId
                        .. "]"
                end,
            }, function(item)
                if not item or item.modelId == models.currentModelId then return end
                run(chat, function(active)
                    if not active:set_model(item.modelId) then error("模型切换失败", 0) end
                    chat:update_metadata()
                    vim.cmd.redrawstatus()
                    notify("当前对话模型：" .. item.modelId)
                end)
            end)
        end)
    end)
end

local function normalize(path)
    path = vim.fs.normalize(path):gsub("/+$", "")
    return vim.fn.has("win32") == 1 and path:lower() or path
end

local function within(cwd, root)
    if type(cwd) ~= "string" or cwd == "" then return false end
    cwd, root = normalize(cwd), normalize(root)
    return cwd == root or cwd:sub(1, #root + 1) == root .. "/"
end

-- 原生 session_list 强制按 cwd 精确匹配，遗漏 Assets/Lua 等子目录的会话。
-- 不传 cwd，分页读取后按项目根目录过滤；不读取凭据或直接解析数据库。
function M.sessions(conn, root)
    local sessions, seen, cursors = {}, {}, {}
    local cursor
    repeat
        local result = conn:send_rpc_request("session/list", cursor and { cursor = cursor } or {})
        if not result then error("读取 Codex 历史失败", 0) end
        for _, item in ipairs(result.sessions or {}) do
            if not seen[item.sessionId] and (not root or within(item.cwd, root)) then
                seen[item.sessionId] = true
                sessions[#sessions + 1] = item
            end
        end
        cursor = type(result.nextCursor) == "string"
                and result.nextCursor ~= ""
                and result.nextCursor
            or nil
        if cursor and cursors[cursor] then error("Codex 历史分页返回重复游标", 0) end
        if cursor then cursors[cursor] = true end
    until not cursor
    table.sort(sessions, function(a, b) return (a.updatedAt or "") > (b.updatedAt or "") end)
    return sessions
end

function M.resume(session, previous)
    if not available(previous) then return end
    -- 本次 Nvim 已打开的会话直接切回，避免第二个 ACP 进程争用同一 ID。
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local existing = require("codecompanion").buf_get_chat(bufnr)
        if
            valid(existing)
            and existing.adapter.name == "codex"
            and existing.acp_connection
            and existing.acp_connection.session_id == session.sessionId
        then
            if not available(existing) then return end
            require("ai.codex").activate(existing)
            return existing
        end
    end
    if not session.cwd or vim.fn.isdirectory(session.cwd) ~= 1 then
        return notify("会话原目录不存在：" .. tostring(session.cwd), vim.log.levels.WARN)
    end
    local project = require("game.project").detect(session.cwd)
    local chat = require("ai.codex").new(project, session.cwd)
    run(chat, function(conn)
        local updates = {}
        -- 当前插件只向等待方返回 nil，保留服务端错误以解释会话占用等情况。
        local rpc_error
        local store = conn.store_rpc_response
        conn.store_rpc_response = function(self, response)
            if response.error then rpc_error = response.error end
            return store(self, response)
        end
        -- 初始化期间用户可能切换目录；在 load 请求发出前恢复原始 cwd。
        vim.cmd.tcd(vim.fn.fnameescape(session.cwd))
        local called, loaded = pcall(conn.load_session, conn, session.sessionId, {
            on_session_update = function(update) updates[#updates + 1] = update end,
        })
        conn.store_rpc_response = store
        if not called then error(loaded, 0) end
        -- 插件 load 失败时可能回退为新会话，必须核对 ID，不能伪装恢复成功。
        if not loaded or conn.session_id ~= session.sessionId then
            if
                rpc_error
                and type(rpc_error.data) == "table"
                and rpc_error.data.reason == "thread_active_writer"
            then
                error(
                    "此会话正在被另一个 Codex 客户端占用。请先在原应用或 CLI 中关闭该会话，再重试；原草稿已保留。",
                    0
                )
            end
            error("历史会话恢复失败；原对话草稿已保留", 0)
        end
        require("codecompanion.interactions.chat.acp.commands").link_buffer_to_session(
            chat.bufnr,
            conn.session_id
        )
        require("codecompanion.interactions.chat.acp.render").restore_session(chat, updates)
        if session.title and session.title ~= vim.NIL then chat:set_title(session.title) end
        chat:update_metadata()
        require("codecompanion.utils").fire("ACPChatRestored", {
            bufnr = chat.bufnr,
            id = chat.id,
            session_id = conn.session_id,
            title = chat.title,
        })
        vim.cmd.redrawstatus()
        notify("已恢复 Codex 对话，可继续输入并按 Ctrl+s 发送")
    end, function()
        if valid(chat) then chat:close() end
        require("ai.codex").activate(previous)
    end)
    return chat
end

function M.history(all, chat)
    chat = resolve(chat)
    if not valid(chat) then return end
    local root = vim.b[chat.bufnr].game_root or require("game.project").detect().root
    notify("正在读取 Codex " .. (all and "全部本地" or "当前项目") .. "历史…")
    run(chat, function(conn)
        if not conn:can_list_sessions() or not conn:can_load_session() then
            error("此 Codex 桥接不支持历史恢复，请检查桥接版本", 0)
        end
        local sessions = M.sessions(conn, not all and root or nil)
        if #sessions == 0 then
            return notify(
                all and "没有可恢复的本地 Codex 历史"
                    or "当前项目暂无历史；按 gH 查看全部本地对话"
            )
        end
        vim.schedule(function()
            if not valid(chat) then return end
            vim.ui.select(sessions, {
                prompt = "恢复 Codex 对话 · " .. (all and "全部本地" or "当前项目"),
                format_item = function(item)
                    local title = type(item.title) == "string"
                            and item.title ~= ""
                            and item.title:gsub("[%c]", " ")
                        or item.sessionId
                    local date = (item.updatedAt or ""):sub(1, 16):gsub("T", " ")
                    return date .. " · " .. title .. " · " .. (item.cwd or "")
                end,
            }, function(item)
                if item then M.resume(item, chat) end
            end)
        end)
    end)
end

return M
