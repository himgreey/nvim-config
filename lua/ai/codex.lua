local M = {}
local chats = {}

function M.command()
    local custom = require("game.config").get().codex_acp
    if custom then return type(custom) == "table" and custom or { custom } end
    local entry = vim.fn.stdpath("data")
        .. "/game-tools/node_modules/@agentclientprotocol/codex-acp/dist/index.js"
    if vim.fn.filereadable(entry) == 1 and vim.fn.executable("node") == 1 then
        -- 直接使用 Node，避免 Windows npm .cmd 包装器影响 stdio ACP。
        return { vim.fn.exepath("node"), entry }
    end
    return { "codex-acp" }
end

local function get_chat(p, fresh)
    p = p or require("game.project").detect()
    -- CodeCompanion 的 ACP session/new 使用 cwd；限制到当前 tab 的引擎根目录。
    vim.cmd.tcd(vim.fn.fnameescape(p.root))
    local cc = require("codecompanion")
    local chat = chats[p.root] or cc.last_chat()
    if
        fresh
        or not chat
        or not vim.api.nvim_buf_is_loaded(chat.bufnr)
        or chat.adapter.type ~= "acp"
        or chat.adapter.name ~= "codex"
        or vim.b[chat.bufnr].game_root ~= p.root
    then
        chat = cc.chat({ params = { adapter = "codex" }, auto_submit = false })
        if chat then vim.b[chat.bufnr].game_root = p.root end
    end
    if chat then
        chats[p.root] = chat
        if cc.last_chat() ~= chat then
            require("codecompanion.interactions.chat").close_last_chat()
        end
    end
    return chat
end

function M.open(p)
    local chat = get_chat(p)
    if chat then chat.ui:open() end
end

function M.add(visual, instruction)
    local context = require("ai.tools").context(visual)
    if not context then return end
    local chat = get_chat()
    if not chat then return end
    chat:add_buf_message({
        role = "user",
        content = context .. (instruction and "\n\n" .. instruction or ""),
    })
    chat.ui:open()
end

function M.edit(visual)
    -- 在输入弹窗之前保存上下文，避免 Visual selection 丢失。
    local context = require("ai.tools").context(visual)
    if not context then return end
    local p = require("game.project").detect()
    vim.ui.input({ prompt = "让 Codex 修改代码：" }, function(prompt)
        if not prompt or vim.trim(prompt) == "" then return end
        local chat = get_chat(p, true)
        if not chat then return end
        chat:add_buf_message({ role = "user", content = context .. "\n\n" .. prompt })
        chat.ui:open()
    end)
end

function M.actions(visual)
    -- 可视模式选择在 vim.ui.select 回调前记录。
    local context = vim.bo.buftype == ""
            and vim.api.nvim_buf_get_name(0) ~= ""
            and require("ai.tools").context(visual)
        or nil
    local p = require("game.project").detect()
    local actions =
        { "Codex 聊天", "解释代码", "检查游戏性能与内存问题", "Codex 终端" }
    vim.ui.select(actions, { prompt = "Codex" }, function(action)
        if not action then return end
        vim.cmd.tcd(vim.fn.fnameescape(p.root))
        if action == actions[4] then
            require("ai.tools").terminal("codex", p)
            return
        end
        if action == actions[1] then
            M.open(p)
            return
        end
        if not context then
            vim.notify("请在代码文件中选择此操作", vim.log.levels.WARN)
            return
        end
        local chat = get_chat(p)
        if not chat then return end
        local instruction = action == actions[2]
                and "解释这段代码的行为与引擎生命周期关系。"
            or "检查这段代码的性能、GC、对象生命周期及潜在错误，给出具体修改建议。"
        chat:add_buf_message({ role = "user", content = context .. "\n\n" .. instruction })
        chat.ui:open()
    end)
end

return M
