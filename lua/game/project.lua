local M = {}

local excludes = {
    unity = { "Library", "Temp", "Obj", "obj", "Build", "Builds", "Logs", "UserSettings", ".vs" },
    godot = { ".godot", ".import", "bin", "obj" },
    unreal = { "Binaries", "DerivedDataCache", "Intermediate", "Saved" },
    generic = { "node_modules", "bin", "obj", ".venv" },
}
local cache = {}
local cache_count = 0

function M.clear_cache()
    cache, cache_count = {}, 0
end

function M.excludes(kind)
    local names = vim.list_extend({ ".git" }, excludes[kind] or excludes.generic)
    return names
end

local function files(dir, suffix)
    local result = {}
    for name, kind in vim.fs.dir(dir) do
        if kind == "file" and name:sub(-#suffix):lower() == suffix:lower() then
            result[#result + 1] = vim.fs.joinpath(dir, name)
        end
    end
    table.sort(result)
    return result
end
M.files = files

-- 从当前文件向上查找；即使从 Assets/ 或 Source/ 启动也能找到引擎根目录。
function M.detect(start)
    if not start and vim.bo.buftype ~= "" then start = vim.b.game_root or vim.fn.getcwd() end
    start = start or vim.api.nvim_buf_get_name(0)
    if start == "" or start:match("^%a+://") then start = vim.b.game_root or vim.fn.getcwd() end
    start = vim.fs.normalize(vim.fn.fnamemodify(start, ":p"))
    local stat = vim.uv.fs_stat(start)
    local dir = stat and stat.type == "directory" and start or vim.fs.dirname(start)
    if not dir then return { kind = "generic", root = vim.fn.getcwd() } end
    local key = vim.fn.has("win32") == 1 and dir:lower() or dir
    local now = vim.uv.hrtime() / 1e6
    if cache[key] and now - cache[key].time < 5000 then return vim.deepcopy(cache[key].project) end
    local function remember(p)
        if cache_count >= 256 then M.clear_cache() end
        if not cache[key] then cache_count = cache_count + 1 end
        cache[key] = { time = now, project = p }
        return vim.deepcopy(p)
    end
    local fallback
    while dir do
        if vim.uv.fs_stat(vim.fs.joinpath(dir, "project.godot")) then
            return remember({ kind = "godot", root = dir })
        end
        if
            vim.uv.fs_stat(vim.fs.joinpath(dir, "Assets"))
            and vim.uv.fs_stat(vim.fs.joinpath(dir, "ProjectSettings"))
        then
            return remember({ kind = "unity", root = dir })
        end
        local projects, dotnet = {}, false
        -- 每层目录只遍历一次，避免分别查找四种后缀。
        for name, kind in vim.fs.dir(dir) do
            if kind == "file" then
                local lower = name:lower()
                if lower:match("%.uproject$") then
                    projects[#projects + 1] = vim.fs.joinpath(dir, name)
                end
                if lower:match("%.sln$") or lower:match("%.slnx$") or lower:match("%.csproj$") then
                    dotnet = true
                end
            end
        end
        table.sort(projects)
        if #projects > 0 then
            return remember({ kind = "unreal", root = dir, project = projects[1] })
        end
        if
            not fallback
            and (
                vim.uv.fs_stat(vim.fs.joinpath(dir, ".git"))
                or vim.uv.fs_stat(vim.fs.joinpath(dir, "CMakeLists.txt"))
                or dotnet
            )
        then
            fallback = dir
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
    end
    return remember({
        kind = "generic",
        root = fallback or (stat and stat.type == "directory" and start or vim.fs.dirname(start)),
    })
end

-- 共享给文件树、搜索和语言服务；只按完整目录名匹配。
function M.excluded(path, project)
    path = vim.fs.normalize(path)
    local possible = false
    for part in path:gmatch("[^/]+") do
        if part:lower() == ".git" then return true end
        for _, names in pairs(excludes) do
            for _, name in ipairs(names) do
                if part:lower() == name:lower() then possible = true end
            end
        end
    end
    if not possible then return false end
    project = project or M.detect(path)
    local relative = vim.fs.relpath(project.root, path)
    if not relative then return false end
    for part in relative:gmatch("[^/]+") do
        for _, name in ipairs(M.excludes(project.kind)) do
            if part:lower() == name:lower() then return true end
        end
    end
    return false
end

function M.picker_opts(all)
    local project = M.detect()
    local ignore = { "**/.git/**" }
    if not all then
        for _, dir in ipairs(excludes[project.kind]) do
            ignore[#ignore + 1] = "**/" .. dir .. "/**"
        end
    end
    return { cwd = project.root, hidden = true, ignored = all or false, exclude = ignore }
end

return M
