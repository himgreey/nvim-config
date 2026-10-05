local M = {}

function M.lua_settings(root)
    root = vim.fs.normalize(root)
    -- 项目显式配置优先；不覆盖已有的库路径、运行时和排除规则。
    if vim.uv.fs_stat(root .. "/.luarc.json") or vim.uv.fs_stat(root .. "/.luarc.jsonc") then
        return
    end
    local project = require("game.project").detect(root)
    local opts = {
        workspace = {
            checkThirdParty = "Disable",
            ignoreDir = vim.list_extend(
                { ".vscode" },
                require("game.project").excludes(project.kind)
            ),
            library = {},
        },
        telemetry = { enable = false },
    }
    local nvim = vim.fs.normalize(vim.fn.stdpath("config"))
    if root:lower() == nvim:lower() then
        opts.runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } }
        opts.diagnostics = { globals = { "vim" } }
        opts.workspace.library = { vim.env.VIMRUNTIME }
    elseif project.kind == "unity" then
        local stubs = project.root .. "/.EmmyLuaUnity"
        if vim.fn.isdirectory(stubs) == 1 then opts.workspace.library = { stubs } end
        opts.diagnostics = { globals = { "CS", "typeof" } }
        opts.runtime =
            { path = { "?.lua", "?/init.lua", "Assets/Lua/?.lua", "Assets/Lua/?/init.lua" } }
        local runtime = require("game.config").get().lua_runtime
        if runtime then opts.runtime.version = runtime end
        opts.hint = { enable = false }
        opts.codeLens = { enable = false }
    end
    return opts
end

function M.guard(name)
    local config = vim.lsp.config[name]
    local root = config.root_dir
    vim.lsp.config(name, {
        root_dir = function(buf, on_dir)
            if require("game.buffer").large(buf) then return end
            if type(root) == "function" then return root(buf, on_dir) end
            on_dir(root or (config.root_markers and vim.fs.root(buf, config.root_markers)))
        end,
    })
end

function M.install(names, servers)
    local packages = {}
    local mapping = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
    if #names == 0 then
        for _, server in ipairs(servers) do
            if vim.tbl_contains(vim.lsp.config[server].filetypes or {}, vim.bo.filetype) then
                names[#names + 1] = server
            end
        end
    end
    for _, name in ipairs(names) do
        if not vim.tbl_contains(servers, name) or not mapping[name] then
            vim.notify("未配置的语言服务：" .. name, vim.log.levels.WARN)
            return
        end
        packages[#packages + 1] = mapping[name]
    end
    if #packages == 0 then
        vim.notify(
            "当前文件没有可安装的 Mason 语言服务；Godot LSP 由编辑器提供",
            vim.log.levels.INFO
        )
        return
    end
    vim.cmd.MasonInstall({ args = packages })
end

return M
