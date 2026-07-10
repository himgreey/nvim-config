-- ============================================
-- Neovim 配置入口
-- ============================================

require("core.options")   -- 加载 options
require("core.keymaps")  -- 加载 keymaps
require("core.proxy")
require("core.autocmds")
require("utils.lazy_bootstrap")
require("plugins.init")
