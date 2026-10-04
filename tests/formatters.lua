-- 运行：nvim --headless -i NONE -u init.lua -c "lua dofile('tests/formatters.lua')"
local ok, err = xpcall(function()
    require("lazy").load({ plugins = { "nvim-lspconfig", "conform.nvim" } })
    local cases = {
        {
            ft = "cs",
            name = "GameFormatterTest.cs",
            text = { "public class GameFormatterTest{public int Speed;}" },
            tool = "csharpier",
        },
        {
            ft = "cpp",
            name = "GameFormatterTest.cpp",
            text = { "int main(){return 0;}" },
            tool = "clang_format",
        },
        {
            ft = "gdscript",
            name = "GameFormatterTest.gd",
            text = { "extends Node", "var speed=1" },
            tool = "gdformat",
        },
    }
    local conform = require("conform")
    for _, case in ipairs(cases) do
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. "-" .. case.name)
        -- 不触发 FileType/LSP 网络连接，直接设置 buffer 选项供 formatter 选择。
        local previous = vim.o.eventignore
        vim.opt.eventignore:append("FileType")
        vim.api.nvim_set_option_value("filetype", case.ft, { buf = buf })
        vim.o.eventignore = previous
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, case.text)
        assert(
            conform.get_formatter_info(case.tool, buf).available,
            "formatter unavailable: " .. case.tool
        )
        local format_error, called
        conform.format(
            { bufnr = buf, async = false, timeout_ms = 10000, lsp_format = "never" },
            function(e)
                format_error, called = e, true
            end
        )
        assert(called and not format_error, vim.inspect(format_error))
        local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        assert(
            table.concat(after, "\n") ~= table.concat(case.text, "\n"),
            case.tool .. " produced no formatting"
        )
        print("PASS: " .. case.tool .. " formatted " .. case.ft)
        vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.cmd("CodeCompanionChat")
    assert(vim.bo.filetype == "codecompanion", "AI chat did not open")
    print("PASS: AI chat opens without sending an API request")
end, debug.traceback)
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
vim.cmd("qa!")
