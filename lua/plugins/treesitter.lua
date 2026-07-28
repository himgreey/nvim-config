-- ============================================
-- Treesitter 语法高亮（nvim-treesitter 新 API，需 Nvim 0.12+）
-- ============================================

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                install_dir = vim.fn.stdpath("data") .. "/site",
            })

            -- 异步安装常用 parser（已安装则 no-op）
            require("nvim-treesitter").install({
                "lua",
                "c_sharp",
                "vim",
                "vimdoc",
                "query",
                "c",
                "cpp",
                "go",
                "rust",
                "python",
                "javascript",
                "typescript",
                "html",
                "css",
                "json",
                "yaml",
                "markdown",
                "markdown_inline",
                "regex",
                "bash",
            })

            -- 新版本不再用 highlight.enable，需自行启动
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    local ok = pcall(vim.treesitter.start, args.buf)
                    if ok then
                        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
