return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.config("*", { capabilities = capabilities })
            vim.diagnostic.config({
                severity_sort = true,
                float = { border = "rounded" },
                virtual_text = { spacing = 2, source = "if_many" },
                update_in_insert = false,
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("GameDevLsp", { clear = true }),
                callback = function(args)
                    local function map(key, fn, desc)
                        vim.keymap.set("n", key, fn, { buffer = args.buf, desc = desc })
                    end
                    map("gd", vim.lsp.buf.definition, "跳转定义")
                    map("gD", vim.lsp.buf.declaration, "跳转声明")
                    map("gi", vim.lsp.buf.implementation, "跳转实现")
                    map("gr", vim.lsp.buf.references, "查找引用")
                    map("K", vim.lsp.buf.hover, "查看文档")
                    map("<leader>ck", vim.lsp.buf.signature_help, "查看函数签名")
                    map("<leader>rn", vim.lsp.buf.rename, "重命名符号")
                    map("<leader>ca", vim.lsp.buf.code_action, "代码操作")
                    map("<leader>fm", vim.lsp.buf.document_symbol, "文件成员")
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client and client.name == "clangd" then
                        map("<leader>ch", function()
                            client:request("textDocument/switchSourceHeader", {
                                uri = vim.uri_from_bufnr(args.buf),
                            }, function(err, uri)
                                if not err and uri and uri ~= "" then
                                    vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
                                end
                            end, args.buf)
                        end, "切换 C++ 头文件/源文件")
                    end
                end,
            })

            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
                        telemetry = { enable = false },
                    },
                },
            })
            vim.lsp.config("omnisharp", {
                root_dir = function(bufnr, on_dir)
                    local p = require("game.project").detect(vim.api.nvim_buf_get_name(bufnr))
                    on_dir(p.root)
                end,
                settings = {
                    FormattingOptions = { EnableEditorConfigSupport = true, OrganizeImports = true },
                    RoslynExtensionsOptions = {
                        EnableAnalyzersSupport = true,
                        EnableImportCompletion = true,
                        AnalyzeOpenDocumentsOnly = true,
                        EnableDecompilationSupport = true,
                    },
                },
            })
            vim.lsp.config("clangd", {
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--completion-style=detailed",
                    "--header-insertion=never",
                },
                root_dir = function(bufnr, on_dir)
                    on_dir(require("game.project").detect(vim.api.nvim_buf_get_name(bufnr)).root)
                end,
            })
            vim.lsp.config("yamlls", {
                root_dir = function(bufnr, on_dir)
                    local file = vim.api.nvim_buf_get_name(bufnr)
                    -- Unity 序列化资源并非通用 YAML schema，避免大量无效诊断。
                    if
                        file:match("%.unity$")
                        or file:match("%.prefab$")
                        or file:match("%.asset$")
                        or file:match("%.meta$")
                    then
                        return
                    end
                    on_dir(require("game.project").detect(file).root)
                end,
            })
            local godot = require("game.config").get()
            vim.lsp.config("gdscript", {
                cmd = vim.lsp.rpc.connect(godot.godot_host, godot.godot_lsp_port),
                root_markers = { "project.godot" },
            })

            local servers = {
                "lua_ls",
                "omnisharp",
                "clangd",
                "jsonls",
                "yamlls",
                "pyright",
                "gopls",
                "rust_analyzer",
                "ts_ls",
            }
            -- 显式白名单，防止已安装的 csharp_ls 与 OmniSharp 同时接管 C#。
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_enable = servers,
            })
            -- 同时支持 PATH 中的工具，不依赖 Mason 的安装状态。
            vim.lsp.enable(servers)
            vim.lsp.enable("gdscript")
        end,
    },
}
