-- ============================================
-- 插件配置入口
-- ============================================

local plugins = {}

-- 按功能拆分
local snacks = require("plugins.snacks")
local tools = require("plugins.tools")
local utils = require("plugins.utils")
local ui_plugins = require("plugins.ui")
local editor_plugins = require("plugins.editor")
local lsp_plugins = require("plugins.lsp")
local cmp_plugins = require("plugins.cmp")
local treesitter_plugins = require("plugins.treesitter")

-- 合并所有插件
for _, plugin in ipairs(ui_plugins) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(editor_plugins) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(lsp_plugins) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(cmp_plugins) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(treesitter_plugins) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(snacks) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(tools) do
    table.insert(plugins, plugin)
end
for _, plugin in ipairs(utils) do
    table.insert(plugins, plugin)
end

-- 启动 Lazy
require("lazy").setup(plugins, {
    defaults = {
        lazy = false,
        version = false,
    },
    install = {
        colorscheme = { "catppuccin" },
    },
    checker = {
        enabled = true,
        frequency = 86400,
    },
    change_detection = {
        enabled = true,
        notify = true,
    },
    performance = {
        cache = {
            enabled = true,
        },
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = {
        border = "rounded",
        size = {
            width = 0.8,
            height = 0.8,
        },
        title = "Lazy.nvim",
    },
})