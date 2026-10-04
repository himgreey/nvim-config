return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")
            ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
            local languages = {
                "lua",
                "c_sharp",
                "c",
                "cpp",
                "gdscript",
                "gdshader",
                "hlsl",
                "glsl",
                "vim",
                "vimdoc",
                "query",
                "python",
                "go",
                "rust",
                "javascript",
                "typescript",
                "html",
                "css",
                "json",
                "yaml",
                "markdown",
                "markdown_inline",
                "bash",
                "xml",
            }
            vim.api.nvim_create_user_command(
                "GameParsersInstall",
                function() ts.install(languages) end,
                {}
            )
            -- 按新版 main API 显式启用高亮；没有 parser 时保留内置语法高亮。
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("GameDevTreesitter", { clear = true }),
                callback = function(args)
                    local buf = args.buf
                    if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_line_count(buf) > 20000 then
                        return
                    end
                    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
                    if stat and stat.size > 1024 * 1024 then return end
                    local ok = pcall(vim.treesitter.start, buf)
                    if
                        ok
                        and not vim.tbl_contains({ "cs", "cpp", "c", "hlsl" }, vim.bo[buf].filetype)
                    then
                        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
}
