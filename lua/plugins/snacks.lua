-- ============================================
-- snacks.nvim - 功能集合插件
-- 替代 alpha-nvim（启动页）和 telescope（部分功能）
-- ============================================

return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            -- 启动页
            dashboard = {
                enabled = true,
                preset = {
                    header = [[
                 +=+======**=++++                                                          
                *         %*      +                                                        
                -        +@#      :=                                                       
               %-   ===:-#@@@+:-    :                                                      
               -   #%*=%@@@@%=+%=   *    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
              #    *@%%@@@@@@%%@=   =    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
              -     *%@@@@@@@@@*:   ::   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
              -      =#@@@@@@#-.    .=   ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
             #    %%%###*###        .:+  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
             =    -:::-+++++-        .-  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          #@#%%@#  =+=+=    ==++  -#+++                                                    
          #%%%%%#  *@%##****#%@@  =@@@@                                                    
            %#%#%*  +%#%%%%%%%%##  =@%%%#                                                    
          *# ##*#*  +%+*%%%%%%#+%  -%%%%#*                                                    
          *# ##=#+  +%#*#%##%%*#%  =%%####*                                                   
                    ]],
                    align = "center",
                },
                sections = {
                    { section = "header" },
                    { section = "keys", gap = 1, padding = 1 },
                    { section = "startup" },
                },
            },
            -- 文件拾取器（替代 telescope）
            picker = {
                enabled = true,
                sources = {
                    files = { hidden = true },
                    grep = { hidden = true },
                },
            },
            -- 通知美化
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            -- 缩进线
            indent = {
                enabled = true,
                indent = { char = "│" },
                scope = { enabled = true },
            },
            -- 快速跳转
            words = {
                enabled = true,
                notify = false,
            },
            -- 终端内图片预览（Windows/cmd 不支持，保持关闭）
            image = { enabled = false },
        },
        config = function(_, opts)
            require("snacks").setup(opts)
            -- image 已禁用时跳过 health 检查，避免 Windows 下误报
            if not opts.image or not opts.image.enabled then
                pcall(function()
                    require("snacks.image").health = function() end
                end)
            end
        end,
        keys = {
            -- 快速打开文件
            { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
            { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep" },
            { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
            { "<leader>fh", function() Snacks.picker.help() end, desc = "Help" },
            -- 快速跳转
            { "<leader>w", function() Snacks.words() end, desc = "Words" },
        },
    },
}