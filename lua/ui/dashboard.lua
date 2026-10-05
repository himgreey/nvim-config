local M = {}
local art = require("ui.art.rei")
local logo = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]]

local function portrait_text(text)
    local lines = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strwidth(line))
    end
    -- 保持整幅点阵的相对坐标，避免居中时每一行被单独挪动。
    for index, line in ipairs(lines) do
        lines[index] = line .. (" "):rep(width - vim.fn.strwidth(line))
    end
    return table.concat(lines, "\n")
end

local function highlights()
    local colors = {
        SnacksDashboardNormal = { fg = "#abb8df", bg = "NONE" },
        SnacksDashboardHeader = { fg = "#aebee9", bold = true },
        SnacksDashboardTitle = { fg = "#82aaff", bold = true },
        SnacksDashboardDesc = { fg = "#a5b2d9" },
        SnacksDashboardIcon = { fg = "#82aaff" },
        SnacksDashboardKey = { fg = "#dc9fbb" },
        SnacksDashboardFile = { fg = "#86cce5" },
        SnacksDashboardDir = { fg = "#62759f" },
        SnacksDashboardFooter = { fg = "#7c91bc" },
        ReiPortrait = { fg = "#aebee9" },
        ReiCaption = { fg = "#dc9fbb", bold = true },
    }
    for name, opts in pairs(colors) do
        vim.api.nvim_set_hl(0, name, opts)
    end
end

function M.projects()
    local dirs, seen = {}, {}
    for _, file in ipairs(vim.v.oldfiles) do
        if vim.fn.filereadable(file) == 1 then
            local root = require("game.project").detect(file).root
            if not seen[root] then
                seen[root] = true
                dirs[#dirs + 1] = root
                if #dirs == 3 then break end
            end
        end
    end
    return dirs
end

function M.sections(dashboard)
    local size = dashboard._size
    local wide = size.width >= 90
    local padding = wide and size.height >= 40 and 1 or 0
    dashboard.opts.width = wide and math.min(60, math.floor((size.width - 6) / 2))
        or math.min(60, size.width - 4)
    local full_logo = dashboard.opts.width >= 52
        and ((wide and size.height >= 32) or (not wide and size.height >= 60))
    local recent = wide and size.height >= 24 or not wide and size.height >= 60
    local projects = wide and size.height >= 24 or not wide and size.height >= 68
    -- 小窗口只缩小整幅人物，绝不切换成裁掉身体的头像。
    local body_height = size.height - (full_logo and 6 or 1) - 1 - padding * 3
    if not wide then
        body_height = body_height - 11 - (recent and 4 or 0) - (projects and 3 or 0)
    end
    local portrait = art.compact
    for _, candidate in ipairs({ art.full, art.medium, art.small, art.compact }) do
        local lines = vim.split(candidate:gsub("\n$", ""), "\n", { plain = true })
        local width = 0
        for _, line in ipairs(lines) do
            width = math.max(width, vim.fn.strwidth(line))
        end
        if #lines <= body_height and width <= dashboard.opts.width then
            portrait = candidate
            break
        end
    end
    local pane = wide and 2 or 1
    local sections = {
        {
            text = { full_logo and logo or "N E O V I M", hl = "SnacksDashboardHeader" },
            align = "center",
            padding = padding,
        },
        {
            text = { portrait_text(portrait), hl = "ReiPortrait" },
            align = "center",
            padding = padding,
        },
        {
            text = {
                dashboard.opts.width >= 22 and "REI AYANAMI  /  EVA-00" or "REI / EVA-00",
                hl = "ReiCaption",
            },
            align = "center",
            padding = padding,
        },
        {
            pane = pane,
            section = "keys",
            title = "常用操作",
            icon = "󰌌 ",
            indent = 2,
            padding = padding,
        },
    }
    if recent then
        sections[#sections + 1] = {
            pane = pane,
            section = "recent_files",
            title = "最近文件",
            icon = " ",
            indent = 2,
            limit = wide and size.height >= 40 and 5 or 3,
            padding = padding,
        }
    end
    if projects then
        sections[#sections + 1] = {
            pane = pane,
            section = "projects",
            title = "最近项目",
            icon = " ",
            indent = 2,
            limit = wide and (size.height >= 40 and 3 or 1) or 2,
            dirs = M.projects,
            session = false,
            padding = padding,
        }
    end
    if dashboard.opts.width >= 42 then
        sections[#sections + 1] = { pane = pane, section = "startup", padding = padding }
    else
        local stats = require("lazy").stats()
        sections[#sections + 1] = {
            pane = pane,
            text = {
                ("%d/%d plugins · %.0fms"):format(stats.loaded, stats.count, stats.startuptime),
                hl = "SnacksDashboardFooter",
            },
            align = "center",
            padding = padding,
        }
    end
    return sections
end

function M.options()
    return {
        enabled = true,
        width = 60,
        pane_gap = 6,
        preset = {
            keys = {
                {
                    icon = " ",
                    key = "f",
                    desc = "查找文件",
                    action = function() Snacks.picker.files(require("game.project").picker_opts()) end,
                },
                { icon = " ", key = "n", desc = "新建文件", action = ":ene | startinsert" },
                {
                    icon = " ",
                    key = "p",
                    desc = "项目",
                    action = function() Snacks.picker.projects() end,
                },
                {
                    icon = " ",
                    key = "g",
                    desc = "搜索内容",
                    action = function() Snacks.picker.grep(require("game.project").picker_opts()) end,
                },
                {
                    icon = " ",
                    key = "r",
                    desc = "最近文件",
                    action = function() Snacks.picker.recent() end,
                },
                {
                    icon = " ",
                    key = "c",
                    desc = "Nvim 配置",
                    action = function()
                        Snacks.picker.files({ cwd = vim.fn.stdpath("config"), hidden = true })
                    end,
                },
                {
                    icon = "󰚩 ",
                    key = "a",
                    desc = "Codex 聊天",
                    action = function() require("ai.codex").open() end,
                },
                { icon = "󰒲 ", key = "l", desc = "插件管理", action = ":Lazy" },
                { icon = " ", key = "q", desc = "退出", action = ":qa" },
            },
        },
        sections = M.sections,
    }
end

function M.setup()
    highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("ReiDashboardColors", { clear = true }),
        callback = highlights,
    })
    vim.api.nvim_create_user_command("Dashboard", function() Snacks.dashboard() end, {})
end

return M
