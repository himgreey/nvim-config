local M = {}
local pending = false
local applying = false

local function clamp(value, low, high) return math.max(low, math.min(high, value)) end

function M.tree_width(columns) return clamp(math.floor((columns or vim.o.columns) * 0.16), 16, 28) end

function M.plan(columns, tree, ai)
    local tree_width = tree and M.tree_width(columns) or 0
    local available = columns - tree_width - (tree and 1 or 0) - (ai and 1 or 0)
    local reserve = columns >= 120 and 60 or columns >= 90 and 40 or 28
    local ai_width = ai
            and math.max(20, math.min(80, math.floor(available * 0.4), available - reserve))
        or 0
    return { tree = tree_width, ai = ai_width, editor = available - ai_width }
end

local function reset_dashboard(win)
    vim.wo[win].sidescrolloff = 0
    vim.api.nvim_win_call(win, function() vim.fn.winrestview({ leftcol = 0 }) end)
end

function M.apply()
    if applying then return end
    applying = true
    local trees, chats, inputs, dashboards = {}, {}, {}, {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            if ft == "NvimTree" then
                trees[#trees + 1] = win
            elseif ft == "codecompanion" then
                chats[#chats + 1] = win
            elseif vim.b[buf].ai_chat_bufnr then
                inputs[vim.b[buf].ai_chat_bufnr] = win
            elseif ft == "snacks_dashboard" then
                dashboards[#dashboards + 1] = win
            end
        end
    end
    local plan = M.plan(vim.o.columns, #trees > 0, #chats > 0)
    local changed = false
    local function width(win, target)
        if vim.api.nvim_win_get_width(win) ~= target then
            vim.api.nvim_win_set_width(win, target)
            changed = true
        end
    end
    for _, win in ipairs(trees) do
        width(win, plan.tree)
    end
    -- 阅读区与输入区属于同一列，缩放这一列，保持中间编辑区域宽度。
    for _, win in ipairs(chats) do
        width(win, plan.ai)
        local input = inputs[vim.api.nvim_win_get_buf(win)]
        if input then
            local total = vim.api.nvim_win_get_height(win) + vim.api.nvim_win_get_height(input)
            local rows = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(input))
            local target = clamp(
                math.max(math.min(6, math.floor(total * 0.16)), rows),
                3,
                math.max(3, math.min(10, math.floor(total * 0.3)))
            )
            if vim.api.nvim_win_get_height(input) ~= target then
                vim.api.nvim_win_set_height(input, target)
                changed = true
            end
        end
    end
    if changed and #dashboards > 0 then Snacks.dashboard.update() end
    for _, win in ipairs(dashboards) do
        reset_dashboard(win)
    end
    applying = false
end

function M.request()
    if pending or applying then return end
    pending = true
    vim.schedule(function()
        pending = false
        M.apply()
    end)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("GameWindowLayout", { clear = true })
    vim.api.nvim_create_autocmd(
        { "WinNew", "WinClosed", "WinResized", "VimResized", "BufWinEnter", "TabEnter" },
        {
            group = group,
            callback = M.request,
        }
    )
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "CodeCompanionChatOpened", "CodeCompanionChatHidden", "SnacksDashboardOpened" },
        callback = M.request,
    })
    -- 首页重排后 Neovim 会保留旧 leftcol；重置视图，避免人物与菜单左侧消失。
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "SnacksDashboardUpdatePost",
        callback = function()
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "snacks_dashboard" then
                    reset_dashboard(win)
                end
            end
        end,
    })
end

return M
