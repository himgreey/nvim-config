local M = { sessions = {} }

-- Windows 的 .cmd/.bat 通过 PowerShell 调用，逐个参数引用，保留空格和特殊字符。
function M.command(argv)
    local resolved = vim.fn.exepath(argv[1])
    if resolved == "" then resolved = argv[1] end
    if
        vim.fn.has("win32") == 1
        and (resolved:lower():match("%.cmd$") or resolved:lower():match("%.bat$"))
    then
        local quoted = { "& '" .. resolved:gsub("'", "''") .. "'" }
        for i = 2, #argv do
            quoted[#quoted + 1] = "'" .. tostring(argv[i]):gsub("'", "''") .. "'"
        end
        return {
            vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell.exe",
            "-NoLogo",
            "-NoProfile",
            "-Command",
            table.concat(quoted, " "),
        }
    end
    return argv
end

function M.open(argv, cwd, id)
    if vim.fn.executable(argv[1]) == 0 then
        vim.notify("找不到可执行文件：" .. argv[1], vim.log.levels.WARN)
        return
    end
    local session = id and M.sessions[id]
    if
        session
        and vim.api.nvim_buf_is_valid(session.buf)
        and vim.fn.jobwait({ session.job }, 0)[1] == -1
    then
        for _, win in ipairs(vim.fn.win_findbuf(session.buf)) do
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
                vim.cmd.startinsert()
                return session
            end
        end
        vim.cmd("botright 15split")
        vim.api.nvim_win_set_buf(0, session.buf)
        vim.cmd.startinsert()
        return session
    end
    vim.cmd("botright 15new")
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].game_root = cwd
    vim.bo[buf].bufhidden = "hide"
    local job = vim.fn.jobstart(M.command(argv), {
        cwd = cwd,
        term = true,
        on_exit = function(_, code)
            vim.schedule(
                function()
                    vim.notify(
                        argv[1] .. " 已退出，代码 " .. code,
                        code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
                    )
                end
            )
        end,
    })
    if job <= 0 then
        vim.notify("启动失败：" .. argv[1], vim.log.levels.ERROR)
        return
    end
    session = { buf = buf, job = job }
    if id then M.sessions[id] = session end
    vim.cmd.startinsert()
    return session
end

return M
