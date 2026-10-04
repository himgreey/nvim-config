-- 在完整配置中运行：nvim --headless -i NONE -u init.lua -c "lua dofile('tests/smoke.lua')"
local ok, err = xpcall(function()
    require("lazy").load({
        plugins = { "nvim-lspconfig", "nvim-cmp", "conform.nvim", "codecompanion.nvim" },
    })
    assert(vim.lsp.is_enabled("omnisharp"))
    assert(vim.lsp.is_enabled("clangd"))
    assert(vim.lsp.is_enabled("gdscript"))
    assert(not vim.lsp.is_enabled("csharp_ls"))
    local caps = vim.lsp.config.omnisharp.capabilities
    assert(caps.textDocument.completion.completionItem.snippetSupport)
    local root
    vim.lsp.config.omnisharp.root_dir(0, function(dir) root = dir end)
    assert(root == require("game.project").detect().root)
    local adapter = require("codecompanion.adapters").resolve("game_ai")
    assert(adapter, "CodeCompanion adapter missing")
    assert(adapter.env.url:match("/v1$"))
    assert(adapter.env.chat_url == "/chat/completions")
    assert(type(adapter.schema.model.default) == "string")
    local conf = require("codecompanion.config").config
    assert(conf.interactions.chat.adapter == "codex")
    local codex = assert(require("codecompanion.adapters").resolve("codex"))
    assert(codex.type == "acp" and codex.defaults.auth_method == "chat-gpt")
    assert(vim.fn.executable(codex.commands.default[1]) == 1)
    for _, kind in ipairs({ "inline", "background", "cmd" }) do
        assert(conf.interactions[kind].adapter == "game_ai")
    end
    local dap = require("dap")
    assert(dap.adapters.godot.port == 6006)
    assert(dap.adapters.codelldb and dap.adapters.coreclr)
    local coreclr, codelldb
    dap.adapters.coreclr(function(adapter) coreclr = adapter end)
    dap.adapters.codelldb(function(adapter) codelldb = adapter end)
    assert(coreclr and vim.fn.executable(coreclr.command) == 1, "netcoredbg executable missing")
    assert(
        codelldb and vim.fn.executable(codelldb.executable.command) == 1,
        "codelldb executable missing"
    )
    assert(not dap.configurations.cs[2].name:find("Unity"))
    local formatters = require("conform").formatters_by_ft
    assert(formatters.cpp[1] == "clang_format" and formatters.gdscript[1] == "gdformat")
    assert(type(formatters.javascript[1]) == "string" and formatters.javascript.stop_after_first)
    assert(vim.fn.exists(":GameBuild") == 2 and vim.fn.exists(":GameParsersInstall") == 2)
    assert(vim.fn.maparg("<C-k>", "n") == "<C-W>k")
    assert(#require("luasnip").get_snippets("gdscript") > 0)
    assert(#require("luasnip").get_snippets("cpp") > 0)
    assert(vim.v.errmsg == "", vim.v.errmsg)
    print("PASS: full startup, LSP, AI adapter, DAP, formatters, snippets and keymaps")
end, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
