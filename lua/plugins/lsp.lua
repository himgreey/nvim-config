-- ============================================
-- LSP 支持
-- ============================================

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "folke/neodev.nvim",
        },
        config = function()
            require("neodev").setup()
            require("mason").setup()

            local has_new_lsp_api = vim.fn.has("nvim-0.11") == 1

            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls", "csharp_ls",
                    "pyright", "gopls", "rust_analyzer",
                    "clangd", "ts_ls", "jsonls", "yamlls",
                },
                automatic_installation = true,
            })

            require("mason-tool-installer").setup({
                ensure_installed = { "stylua", "csharpier" },
                run_on_start = true,
            })

            local lspconfig = require("lspconfig")
            
            local on_attach = function(client, bufnr)
                local bufopts = { noremap = true, silent = true, buffer = bufnr }
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
                vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
                vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                vim.keymap.set("n", "<leader>f", function()
                    vim.lsp.buf.format { async = true }
                end, bufopts)
            end

            if has_new_lsp_api then
                vim.lsp.config("lua_ls", {
                    cmd = { "lua-language-server" },
                    filetypes = { "lua" },
                    root_markers = { ".luarc.json", ".luacheckrc", ".git" },
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                        },
                    },
                })
                
                vim.lsp.config("pyright", {
                    cmd = { "pyright-langserver", "--stdio" },
                    filetypes = { "python" },
                })

                vim.lsp.config("csharp_ls", {
                    cmd = { "csharp-ls" },
                    filetypes = { "cs", "csharp" },
                    root_markers = { "*.sln", "*.csproj", ".git" },
                })

                -- mason-lspconfig 会自动 enable 已安装的服务器
                
                vim.api.nvim_create_autocmd("LspAttach", {
                    callback = function(args)
                        local client = vim.lsp.get_client_by_id(args.data.client_id)
                        if client then
                            on_attach(client, args.buf)
                        end
                    end,
                })
            else
                local capabilities = vim.lsp.protocol.make_client_capabilities()
                
                lspconfig.lua_ls.setup({
                    on_attach = on_attach,
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                        },
                    },
                })
                
                lspconfig.pyright.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.gopls.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.rust_analyzer.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.clangd.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.ts_ls.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.jsonls.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.yamlls.setup({ on_attach = on_attach, capabilities = capabilities })
                lspconfig.csharp_ls.setup({ on_attach = on_attach, capabilities = capabilities })
            end
        end,
    },
}