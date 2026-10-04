local M = {}

function M.terminal(name, p)
    p = p or require("game.project").detect()
    local argv = require("game.config").get().ai[name]
    if not argv then return end
    require("game.terminal").open(argv, p.root, p.root .. ":ai:" .. name)
end

function M.context(visual)
    local buf = vim.api.nvim_get_current_buf()
    local p = require("game.project").detect()
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" or vim.bo[buf].buftype ~= "" then
        vim.notify("请在代码文件中复制 AI 上下文", vim.log.levels.WARN)
        return
    end
    local first, last = 1, vim.api.nvim_buf_line_count(buf)
    if visual then
        first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then
            first, last = last, first
        end
    end
    local lines = vim.api.nvim_buf_get_lines(buf, first - 1, last, false)
    local relative = vim.fs.relpath(p.root, file) or file
    local text = {
        "请用简体中文回答。代码和技术术语保留原文。",
        "引擎：" .. p.kind,
        ("文件：%s，行 %d-%d"):format(relative, first, last),
        "```" .. vim.bo[buf].filetype,
    }
    vim.list_extend(text, lines)
    text[#text + 1] = "```"
    local diagnostics = vim.diagnostic.get(buf)
    for _, d in ipairs(diagnostics) do
        if d.lnum + 1 >= first and d.lnum + 1 <= last then
            text[#text + 1] = ("诊断 %d: %s"):format(d.lnum + 1, d.message)
        end
    end
    return table.concat(text, "\n")
end

function M.copy(visual)
    local context = M.context(visual)
    if not context then return end
    vim.fn.setreg("+", context)
    vim.notify("已复制代码、引擎信息和诊断，可粘贴到 AI 工具")
end

return M
