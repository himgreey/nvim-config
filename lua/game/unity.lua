local M = {}

function M.open(kind)
    local file = vim.api.nvim_buf_get_name(0)
    if file == "" or vim.bo.buftype ~= "" then return end
    local target
    if kind == "meta" then
        target = file:match("%.meta$") and file:gsub("%.meta$", "") or file .. ".meta"
    elseif file:match("%.cs$") then
        -- 只替换文件名的后缀；目录名中的 Tests 必须保持原样。
        target = file:match("Test%.cs$") and file:gsub("Test%.cs$", ".cs")
            or file:gsub("%.cs$", "Test.cs")
    end
    if target and vim.fn.filereadable(target) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(target))
    else
        vim.notify("未找到对应文件：" .. (target or file), vim.log.levels.WARN)
    end
end

return M
