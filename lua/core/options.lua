-- ============================================
-- Neovim 基础选项
-- ============================================

-- 禁用不需要的 provider（提升启动速度）
vim.g.node_host_prog = nil
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Swap 文件管理
local swap_dir = vim.fn.stdpath("state") .. "/swap/"
if vim.fn.isdirectory(swap_dir) == 0 then
    vim.fn.mkdir(swap_dir, "p")
end
vim.opt.directory = swap_dir

-- ===== 你的原有配置 =====
vim.opt.shiftwidth = 4
vim.opt.expandtab = false      -- 使用 Tab 而不是空格
vim.opt.number = true
vim.opt.showcmd = true
vim.opt.tabstop = 2            -- ts=2
vim.opt.softtabstop = 2        -- sw=2
vim.opt.cursorline = true
vim.opt.cursorcolumn = true    -- 你开启了列高亮
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.autoread = true
vim.opt.history = 500
vim.opt.title = true
vim.opt.confirm = true
vim.opt.encoding = "utf-8"

-- ===== 额外配置（保持原有的） =====
vim.opt.updatetime = 100
vim.opt.redrawtime = 1500
vim.opt.fileencoding = "utf-8"
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.backup = false
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.relativenumber = true
vim.opt.wrap = false
vim.opt.showmatch = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.laststatus = 3
vim.opt.cmdheight = 1
vim.opt.pumheight = 10
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.showmode = false

-- 光标样式
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- 透明背景
vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
vim.cmd("highlight NonText guibg=NONE ctermbg=NONE")