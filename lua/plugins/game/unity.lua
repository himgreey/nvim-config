return {
    {
        "apyra/nvim-unity-sync",
        lazy = true,
        cmd = { "Ustatus", "Usync", "Uopen" },
        dependencies = { "nvim-tree/nvim-tree.lua" },
        config = function()
            local before = {}
            for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeave" })) do
                before[autocmd.id] = true
            end
            require("unity.plugin").setup({
                unity_path = require("game.config").get().unity,
                unity_cs_template = false,
            })
            -- 上游退出钩子无条件执行 pkill -f unity2025；保留编辑器进程和同步功能。
            for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimLeave" })) do
                if not before[autocmd.id] and type(autocmd.callback) == "function" then
                    local source = debug.getinfo(autocmd.callback, "S").source:gsub("\\", "/")
                    if source:match("/unity/plugin%.lua$") then
                        vim.api.nvim_del_autocmd(autocmd.id)
                    end
                end
            end
        end,
    },
}
