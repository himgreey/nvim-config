-- ============================================
-- 自动命令
-- ============================================

-- 自动清理超过 24 小时的残留 swap 文件
local swap_dir = vim.fn.stdpath("state") .. "/swap/"
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local files = vim.fn.glob(swap_dir .. "*.sw?", false, true)
        local now = vim.fn.localtime()
        for _, file in ipairs(files) do
            if now - vim.fn.getftime(file) > 86400 then
                os.remove(file)
            end
        end
    end,
})

-- 延迟加载 notify
vim.defer_fn(function()
    local ok, notify = pcall(require, "notify")
    if ok then
        notify.setup({
            background_colour = "#000000",
            timeout = 3000,
            level = vim.log.levels.INFO,
        })
    end
end, 100)