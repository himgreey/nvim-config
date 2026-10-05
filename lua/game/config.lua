-- 路径和端口可通过环境变量或 init.lua 中的 vim.g.game_dev 覆盖。
local M = {}
function M.get()
    return vim.tbl_deep_extend("force", {
        unity = vim.env.UNITY_EDITOR,
        godot = vim.env.GODOT_BIN,
        unreal = vim.env.UNREAL_ENGINE_PATH,
        godot_host = "127.0.0.1",
        godot_lsp_port = tonumber(vim.env.GODOT_LSP_PORT or vim.env.GDScript_Port) or 6005,
        godot_dap_port = tonumber(vim.env.GODOT_DAP_PORT) or 6006,
        godot_debug_port = tonumber(vim.env.GODOT_DEBUG_PORT) or 6007,
        netcoredbg = vim.env.NETCOREDBG,
        codelldb = vim.env.CODELLDB,
        codex_acp = vim.env.CODEX_ACP_BIN,
        ai = { codex = { "codex" }, claude = { "claude" } },
        performance = { max_file_bytes = 1024 * 1024, max_file_lines = 20000 },
        ai_context = { max_bytes = 64 * 1024, max_lines = 1500, max_diagnostics = 50 },
    }, vim.g.game_dev or {})
end
return M
