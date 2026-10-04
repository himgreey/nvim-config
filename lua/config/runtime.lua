-- ============================================
-- 代理配置
-- ============================================

-- 保留现有代理环境变量；仅在显式设置时使用 Nvim 专用代理。
-- 例如 NVIM_HTTP_PROXY=http://127.0.0.1:7897，不再强制所有下载/API 使用此端口。
local proxy = vim.env.NVIM_HTTP_PROXY or (vim.g.game_dev or {}).proxy
if proxy and proxy ~= "" then
    vim.env.HTTP_PROXY = proxy
    vim.env.HTTPS_PROXY = proxy
end

-- 仅调整 Neovim 进程的 PATH，不修改系统环境变量。
if vim.fn.executable("python") == 0 and vim.fn.executable("python3") == 0 then
    local python = vim.env.NVIM_PYTHON_BIN
    if not python and vim.fn.executable("uv") == 1 then
        local found = vim.fn.system({ "uv", "python", "find", "3.12", "--system" })
        if vim.v.shell_error ~= 0 then
            found = vim.fn.system({ "uv", "python", "find", "--system" })
        end
        if vim.v.shell_error == 0 then python = vim.trim(found) end
    end
    if python and vim.fn.executable(python) == 1 then
        vim.env.PATH = vim.fs.dirname(python)
            .. (vim.fn.has("win32") == 1 and ";" or ":")
            .. vim.env.PATH
    end
end

-- Windows 上 tree-sitter-cli 默认选择 cl.exe；没有 MSVC 时使用已安装的 MinGW。
if
    vim.fn.has("win32") == 1
    and not vim.env.CC
    and vim.fn.executable("cl") == 0
    and vim.fn.executable("gcc") == 1
then
    vim.env.CC = vim.fn.exepath("gcc")
    if not vim.env.CXX and vim.fn.executable("g++") == 1 then
        vim.env.CXX = vim.fn.exepath("g++")
    end
end
