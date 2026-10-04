local M = {}

local excludes = {
    unity = { "Library", "Temp", "Obj", "Build", "Builds", "Logs", "UserSettings" },
    godot = { ".godot", ".import", "bin", "obj" },
    unreal = { "Binaries", "DerivedDataCache", "Intermediate", "Saved" },
    generic = { "node_modules", "bin", "obj", ".venv" },
}

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
    local fallback
    while dir do
        if vim.uv.fs_stat(vim.fs.joinpath(dir, "project.godot")) then
            return { kind = "godot", root = dir }
        end
        if
            vim.uv.fs_stat(vim.fs.joinpath(dir, "Assets"))
            and vim.uv.fs_stat(vim.fs.joinpath(dir, "ProjectSettings"))
        then
            return { kind = "unity", root = dir }
        end
        local projects = files(dir, ".uproject")
        if #projects > 0 then return { kind = "unreal", root = dir, project = projects[1] } end
        if
            not fallback
            and (
                vim.uv.fs_stat(vim.fs.joinpath(dir, ".git"))
                or vim.uv.fs_stat(vim.fs.joinpath(dir, "CMakeLists.txt"))
                or #files(dir, ".sln") > 0
                or #files(dir, ".slnx") > 0
                or #files(dir, ".csproj") > 0
            )
        then
            fallback = dir
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then break end
        dir = parent
    end
    return {
        kind = "generic",
        root = fallback or (stat and stat.type == "directory" and start or vim.fs.dirname(start)),
    }
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
