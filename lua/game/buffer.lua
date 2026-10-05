local M = {}

function M.large(buf)
    if buf == nil or buf == 0 then buf = vim.api.nvim_get_current_buf() end
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then return false end
    if vim.b[buf].game_large_file then return true end
    local limits = require("game.config").get().performance
    local count = vim.api.nvim_buf_line_count(buf)
    local bytes = vim.api.nvim_buf_get_offset(buf, count)
    return count > limits.max_file_lines or bytes > limits.max_file_bytes
end

function M.apply(buf)
    if not M.large(buf) then return end
    vim.b[buf].game_large_file = true
    vim.bo[buf].syntax = ""
    vim.bo[buf].indentexpr = ""
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.wo[win].cursorcolumn = false
    end
    pcall(vim.treesitter.stop, buf)
    vim.diagnostic.enable(false, { bufnr = buf })
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
        vim.lsp.buf_detach_client(buf, client.id)
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("GameLargeFiles", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPre", {
        group = group,
        callback = function(args)
            local stat = vim.uv.fs_stat(args.file)
            vim.b[args.buf].game_large_file = stat
                    and stat.size > require("game.config").get().performance.max_file_bytes
                or false
        end,
    })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter", "BufWritePre" }, {
        group = group,
        callback = function(args) M.apply(args.buf) end,
    })
    -- Lazy 重放 FileType 和内置 syntaxset 会在较晚阶段重新设置 syntax。
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            if not M.large(args.buf) then return end
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then M.apply(args.buf) end
            end)
        end,
    })
end

return M
