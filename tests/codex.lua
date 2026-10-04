-- 真实 ACP 握手和会话测试；不发送推理请求，不读取或打印登录凭据。
local connection
local original_cwd, original_input, original_select = vim.fn.getcwd(), vim.ui.input, vim.ui.select
local fixtures = vim.fn.tempname() .. " codex project fixtures"
local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "codecompanion.nvim" } })
    local submitted = 0
    vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatSubmitted",
        callback = function() submitted = submitted + 1 end,
    })
    local function source(project)
        local root = vim.fs.normalize(fixtures .. "/" .. project)
        vim.fn.mkdir(root .. "/scripts", "p")
        vim.fn.writefile({ "[application]" }, root .. "/project.godot")
        local file = root .. "/scripts/player.gd"
        vim.fn.writefile({ "extends Node", "var codex_fixture_speed = 1" }, file)
        vim.cmd("noautocmd edit " .. vim.fn.fnameescape(file))
        return root, vim.api.nvim_get_current_buf()
    end
    local root, buf = source("Godot One")
    require("ai.codex").add(false)
    local chat = assert(require("codecompanion").last_chat())
    assert(chat.adapter.name == "codex" and chat.adapter.type == "acp")
    assert(vim.fs.normalize(vim.fn.getcwd()) == root)
    assert(vim.b[chat.bufnr].game_root == root)
    local draft = table.concat(vim.api.nvim_buf_get_lines(chat.bufnr, 0, -1, false), "\n")
    assert(draft:find("codex_fixture_speed", 1, true) and draft:find("scripts/player.gd", 1, true))
    chat.ui:hide()
    vim.api.nvim_set_current_buf(buf)
    require("ai.codex").open()
    assert(require("codecompanion").last_chat() == chat, "Same project chat was not reused")
    chat.ui:hide()
    vim.api.nvim_set_current_buf(buf)
    vim.ui.input = function(_, callback) callback("请修改 codex_fixture_speed") end
    require("ai.codex").edit(false)
    vim.ui.input = original_input
    local edit = assert(require("codecompanion").last_chat())
    assert(edit ~= chat and vim.b[edit.bufnr].game_root == root)
    assert(
        table
            .concat(vim.api.nvim_buf_get_lines(edit.bufnr, 0, -1, false), "\n")
            :find("请修改 codex_fixture_speed", 1, true)
    )
    edit.ui:hide()
    local second_root, second_buf = source("Godot Two")
    require("ai.codex").open()
    local second_chat = assert(require("codecompanion").last_chat())
    assert(second_chat ~= edit and vim.b[second_chat.bufnr].game_root == second_root)
    second_chat.ui:hide()
    vim.api.nvim_set_current_buf(buf)
    require("ai.codex").open()
    assert(
        require("codecompanion").last_chat() == edit,
        "Returning to a project lost its previous chat"
    )
    edit.ui:hide()
    vim.api.nvim_set_current_buf(buf)
    local select_callback
    vim.ui.select = function(_, _, callback) select_callback = callback end
    require("ai.codex").actions(false)
    vim.api.nvim_set_current_buf(second_buf)
    select_callback("检查游戏性能与内存问题")
    vim.ui.select = original_select
    assert(
        vim.b[require("codecompanion").last_chat().bufnr].game_root == root,
        "Async action used a different project than its captured code"
    )
    assert(submitted == 0, "A draft submitted automatically")
    print("PASS: Codex project roots, code context, edit drafts and no automatic submission")
    local adapter = assert(require("codecompanion.adapters").resolve("codex"))
    assert(adapter.type == "acp")
    local command = require("ai.codex").command()
    assert(vim.fn.executable(command[1]) == 1, "Codex ACP command unavailable")
    connection = require("codecompanion.acp").new({ adapter = adapter })
    assert(connection:start_agent_process(), "Codex ACP process failed")
    assert(connection:_initialize(), "Codex ACP handshake failed")
    local found, ids = false, {}
    for _, method in ipairs(connection._agent_info.authMethods or {}) do
        ids[#ids + 1] = method.id
        if method.id == adapter.defaults.auth_method then found = true end
    end
    print("ACP auth methods: " .. table.concat(ids, ", "))
    assert(found, "Configured Codex auth method is unavailable")
    assert(connection:_authenticate(), "Codex ChatGPT authentication failed")
    assert(connection:ensure_session(), "Codex session creation failed")
    assert(connection:is_connected(), "Codex session not connected")
    print("PASS: real Codex ACP handshake, ChatGPT authentication and session creation")
end, debug.traceback)
if connection and connection._state.handle then connection:disconnect() end
vim.ui.input = original_input
vim.ui.select = original_select
vim.cmd.tcd(vim.fn.fnameescape(original_cwd))
-- 只清理本次创建的独立临时项目。
vim.fn.delete(fixtures, "rf")
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
