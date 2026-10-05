local M = {}
local entries = {}
local ns = vim.api.nvim_create_namespace("GameAIInput")

local function live(chat) return chat and vim.api.nvim_buf_is_loaded(chat.bufnr) end
local function window(win) return win and vim.api.nvim_win_is_valid(win) end
local function notify(text) vim.notify(text, vim.log.levels.WARN, { title = "Codex" }) end

function M.current() return require("codecompanion").buf_get_chat(vim.b.ai_chat_bufnr or 0) end

local function button(chat, id, label)
    return "%" .. (chat.bufnr * 10 + id) .. "@v:lua.NvimAIButton@[" .. label .. "]%X"
end

function M.toolbar(chat, input)
    local compact = vim.api.nvim_win_get_width(0) < 45
    if input then
        local state = chat._game_panel_busy and "同步中"
            or chat.current_request and "生成中"
            or "消息输入"
        return " "
            .. button(chat, 1, compact and "发" or "发送")
            .. " "
            .. button(chat, 2, compact and "停" or "停止")
            .. " "
            .. button(chat, 3, compact and "收" or "收起")
            .. " %=%<"
            .. state
            .. (compact and " " or " · Ctrl+s 发送 ")
    end
    local metadata = (_G.codecompanion_chat_metadata or {})[chat.bufnr]
    local model = metadata and metadata.adapter.model or "连接中…"
    return " %<"
        .. tostring(model):gsub("%%", "%%%%")
        .. " %= "
        .. button(chat, 4, compact and "模" or "模型 gm")
        .. " "
        .. button(chat, 5, compact and "史" or "历史 gh")
        .. " "
        .. button(chat, 6, compact and "⋯" or "更多")
        .. " "
end

function M.status()
    local chat = M.current()
    if not live(chat) then return " AI " end
    return M.toolbar(chat, vim.b.ai_chat_bufnr ~= nil)
end

local function placeholder(entry)
    if not vim.api.nvim_buf_is_valid(entry.bufnr) then return end
    vim.api.nvim_buf_clear_namespace(entry.bufnr, ns, 0, -1)
    local text = table.concat(vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false), "\n")
    if text == "" then
        vim.api.nvim_buf_set_extmark(entry.bufnr, ns, 0, 0, {
            virt_text = {
                { "输入问题…", "Comment" },
            },
            virt_text_pos = "overlay",
        })
    end
end

local function return_to_editor(chat, win)
    local source = chat.buffer_context and chat.buffer_context.bufnr
    if not source or not vim.api.nvim_buf_is_loaded(source) or vim.bo[source].buftype ~= "" then
        source = vim.api.nvim_create_buf(true, false)
    end
    vim.api.nvim_win_set_buf(win, source)
    vim.wo[win].winbar = ""
    vim.wo[win].winfixheight = false
    vim.wo[win].number, vim.wo[win].relativenumber = vim.o.number, vim.o.relativenumber
end

function M.hide(chat)
    local entry = chat and entries[chat.bufnr]
    if entry and window(entry.win) then
        if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(entry.win)) == 1 then
            return_to_editor(chat, entry.win)
        else
            vim.api.nvim_win_close(entry.win, true)
        end
        entry.win = nil
    end
end

function M.close(chat)
    if not live(chat) then return end
    vim.cmd.stopinsert()
    M.hide(chat)
    if not chat.ui:is_visible() then return end
    if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(chat.ui.winnr)) == 1 then
        return_to_editor(chat, chat.ui.winnr)
        require("codecompanion.utils").fire("ChatHidden", { bufnr = chat.bufnr, id = chat.id })
    else
        chat.ui:hide()
    end
end

function M.stop(chat)
    if live(chat) and (chat.current_request or chat.tool_orchestrator) then chat:stop() end
end

function M.send(chat)
    if not live(chat) then return end
    local entry = entries[chat.bufnr]
    if not entry then return end
    if chat.current_request or chat._game_panel_busy then
        return notify("请等待当前操作完成，或先停止生成；输入内容已保留")
    end
    local text = table.concat(vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false), "\n")
    if vim.trim(text) == "" then
        return notify("请输入消息；已有代码草稿可在阅读区按 Ctrl+s 发送")
    end
    -- 提交被插件的大小检查或回调拒绝时，恢复阅读区，不重复追加同一条输入。
    local snapshot = {
        lines = vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false),
        messages = vim.deepcopy(chat.messages),
        builder = vim.deepcopy(chat.builder.state),
        role = chat._last_role,
        header = chat.header_line,
    }
    entry.accepted, entry.sending = false, true
    local ok, err = pcall(function()
        chat:add_buf_message({ role = "user", content = text })
        chat:submit()
    end)
    entry.sending = false
    if not entry.accepted and live(chat) then
        vim.bo[chat.bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(chat.bufnr, 0, -1, false, snapshot.lines)
        chat.messages, chat.builder.state = snapshot.messages, snapshot.builder
        chat._last_role, chat.header_line = snapshot.role, snapshot.header
    end
    if not ok then notify("消息未发送：" .. tostring(err)) end
end

function M.switch(chat)
    if not live(chat) then return end
    local entry = entries[chat.bufnr]
    if entry and window(entry.win) and vim.api.nvim_get_current_win() == entry.win then
        if window(chat.ui.winnr) then
            vim.cmd.stopinsert()
            vim.api.nvim_set_current_win(chat.ui.winnr)
        end
    else
        M.open(chat, true)
    end
end

function M.menu(chat)
    if not live(chat) then return end
    local items = {
        "输入消息",
        "选择模型",
        "项目历史",
        "全部本地历史",
        "新建对话",
        "已打开的对话",
        "停止生成",
        "收起面板",
    }
    vim.ui.select(items, { prompt = "AI 面板操作" }, function(item)
        if not item or not live(chat) then return end
        local panel = require("ai.panel")
        if item == items[1] then
            M.open(chat, true)
        elseif item == items[2] then
            panel.models(chat)
        elseif item == items[3] then
            panel.history(false, chat)
        elseif item == items[4] then
            panel.history(true, chat)
        elseif item == items[5] then
            require("ai.codex").new(require("game.project").detect(vim.b[chat.bufnr].game_root))
        elseif item == items[6] then
            local chats = {}
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local candidate = require("codecompanion").buf_get_chat(buf)
                if live(candidate) and candidate.adapter.name == "codex" then
                    chats[#chats + 1] = candidate
                end
            end
            vim.ui.select(chats, {
                prompt = "已打开的 Codex 对话",
                format_item = function(c)
                    return (c.title or ("对话 " .. c.id))
                        .. " · "
                        .. (vim.b[c.bufnr].game_root or "")
                end,
            }, function(c)
                if live(c) then require("ai.codex").activate(c) end
            end)
        elseif item == items[7] then
            M.stop(chat)
        elseif item == items[8] then
            M.close(chat)
        end
    end)
end

function M.click(id, _, mouse)
    if mouse ~= "l" then return end
    local chat = require("codecompanion").buf_get_chat(math.floor(id / 10))
    if not live(chat) then return end
    local actions = {
        function() M.send(chat) end,
        function() M.stop(chat) end,
        function() M.close(chat) end,
        function() require("ai.panel").models(chat) end,
        function() require("ai.panel").history(false, chat) end,
        function() M.menu(chat) end,
    }
    local action = actions[id % 10]
    if action then action() end
end

local function create(chat)
    local buf = vim.api.nvim_create_buf(false, true)
    local entry = { bufnr = buf, chat = chat }
    entries[chat.bufnr] = entry
    vim.b[buf].ai_chat_bufnr = chat.bufnr
    vim.b[buf].game_root = vim.b[chat.bufnr].game_root
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].filetype = "codecompanion_input"
    vim.bo[buf].swapfile, vim.bo[buf].undofile = false, false
    vim.bo[buf].textwidth = 0
    local function map(modes, key, fn, description)
        vim.keymap.set(modes, key, fn, { buffer = buf, silent = true, desc = description })
    end
    map({ "n", "i" }, "<C-s>", function() M.send(chat) end, "发送 AI 消息")
    map({ "n", "i" }, "<Tab>", function() M.switch(chat) end, "切换 AI 阅读区")
    map({ "n", "i" }, "<C-q>", function() M.stop(chat) end, "停止 AI 生成")
    map({ "n", "i" }, "<C-c>", function() M.close(chat) end, "收起 AI 面板并保留输入")
    map("n", "gm", function() require("ai.panel").models(chat) end, "选择 AI 模型")
    map("n", "gh", function() require("ai.panel").history(false, chat) end, "Codex 项目历史")
    map("n", "gH", function() require("ai.panel").history(true, chat) end, "Codex 全部历史")
    map("n", "g?", function() M.menu(chat) end, "AI 面板操作菜单")
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = buf,
        callback = function()
            placeholder(entry)
            require("ui.layout").request()
        end,
    })
    placeholder(entry)
    return entry
end

function M.open(chat, focus)
    chat = chat or M.current() or require("ai.codex").open()
    if not live(chat) or not chat.ui:is_visible() then return end
    local entry = entries[chat.bufnr]
    if not entry or not vim.api.nvim_buf_is_valid(entry.bufnr) then entry = create(chat) end
    if not window(entry.win) then
        -- 小终端也保留完整阅读区，输入框占约四分之一高度。
        local height =
            math.max(3, math.min(6, math.floor(vim.api.nvim_win_get_height(chat.ui.winnr) * 0.16)))
        vim.api.nvim_win_call(chat.ui.winnr, function()
            vim.cmd("belowright " .. height .. "split")
            entry.win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(entry.win, entry.bufnr)
        end)
        for key, value in pairs({
            number = false,
            relativenumber = false,
            signcolumn = "no",
            foldcolumn = "0",
            wrap = true,
            linebreak = true,
            cursorline = false,
            cursorcolumn = false,
            winfixheight = true,
            spell = false,
            scrolloff = 0,
            winbar = "%{%v:lua.require('ai.composer').status()%}",
        }) do
            vim.wo[entry.win][key] = value
        end
    end
    require("ui.layout").request()
    if focus then
        vim.api.nvim_set_current_win(entry.win)
        vim.cmd.startinsert()
    end
    return entry
end

function M.setup()
    _G.NvimAIButton = M.click
    local group = vim.api.nvim_create_augroup("GameAIComposer", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "CodeCompanionChatOpened", "CodeCompanionChatCreated" },
        callback = function(args)
            local buf = args.data and args.data.bufnr
            vim.schedule(function()
                local chat = buf and require("codecompanion").buf_get_chat(buf)
                if live(chat) and chat.ui:is_visible() then M.open(chat, false) end
            end)
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "CodeCompanionChatHidden", "CodeCompanionChatClosed" },
        callback = function(args)
            local buf = args.data and args.data.bufnr
            local entry = entries[buf]
            if not entry then return end
            M.hide(entry.chat)
            if args.match == "CodeCompanionChatClosed" then
                entries[buf] = nil
                if vim.api.nvim_buf_is_valid(entry.bufnr) then
                    vim.api.nvim_buf_delete(entry.bufnr, { force = true })
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "CodeCompanionChatSubmitted",
        callback = function(args)
            local entry = entries[args.data and args.data.bufnr]
            if not entry or not entry.sending then return end
            entry.accepted = true
            vim.api.nvim_buf_set_lines(entry.bufnr, 0, -1, false, { "" })
            vim.bo[entry.bufnr].modified = false
            placeholder(entry)
        end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function()
            vim.schedule(function()
                for _, entry in pairs(entries) do
                    if not live(entry.chat) or not entry.chat.ui:is_visible() then
                        M.hide(entry.chat)
                    end
                end
            end)
        end,
    })
end

return M
