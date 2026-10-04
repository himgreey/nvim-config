local group = vim.api.nvim_create_augroup("UserEditor", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(args)
        local buf = args.buf
        if
            vim.bo[buf].buftype ~= ""
            or vim.tbl_contains({ "gitcommit", "gitrebase", "hgcommit" }, vim.bo[buf].filetype)
        then
            return
        end
        local mark = vim.api.nvim_buf_get_mark(buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    callback = function(args)
        if vim.bo[args.buf].buftype == "" then
            local cursor = vim.api.nvim_win_get_cursor(0)
            pcall(vim.api.nvim_buf_set_mark, args.buf, '"', cursor[1], cursor[2], {})
        end
    end,
})
vim.api.nvim_create_autocmd({ "FocusGained", "TermLeave" }, {
    group = group,
    callback = function()
        if vim.fn.mode() ~= "c" then vim.cmd.checktime() end
    end,
})
