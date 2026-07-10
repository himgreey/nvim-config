-- ============================================
-- Treesitter 语法高亮
-- ============================================

return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                ensure_installed = {
                    "lua", "vim", "vimdoc", "query",
                    "c", "cpp", "go", "rust", "python",
                    "javascript", "typescript", "html", "css",
                    "json", "yaml", "markdown", "regex", "bash",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = {
                    enable = true,
                },
            })
        end,
    },
}