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
    local limits = require("game.config").get().ai_context
    local bytes = vim.api.nvim_buf_get_offset(buf, last)
        - vim.api.nvim_buf_get_offset(buf, first - 1)
    if last - first + 1 > limits.max_lines or bytes > limits.max_bytes then
        vim.notify(
            ("AI 上下文过大（%d 行 / %.1f KB），请缩小选区；上限 %d 行 / %d KB"):format(
                last - first + 1,
                bytes / 1024,
                limits.max_lines,
                limits.max_bytes / 1024
            ),
            vim.log.levels.WARN
        )
        return
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
    local used = #table.concat(text, "\n")
    if used > limits.max_bytes then
        vim.notify("AI 上下文超过大小上限，请缩小选区", vim.log.levels.WARN)
        return
    end
    local diagnostics = vim.diagnostic.get(buf)
    local count = 0
    local omitted = "其余诊断已省略；可在 Nvim 中查看完整诊断。"
    for _, d in ipairs(diagnostics) do
        if d.lnum + 1 >= first and d.lnum + 1 <= last then
            count = count + 1
            local message = ("诊断 %d: %s"):format(d.lnum + 1, d.message)
            if
                count > limits.max_diagnostics
                or used + #message + #omitted + 2 > limits.max_bytes
            then
                if used + #omitted + 1 <= limits.max_bytes then text[#text + 1] = omitted end
                break
            end
            text[#text + 1] = message
            used = used + #message + 1
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
