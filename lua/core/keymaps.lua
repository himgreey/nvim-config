-- ============================================
-- 快捷键映射
-- ============================================

-- 设置 Leader 键
vim.g.mapleader = " "

-- 定义快捷键（使用 Neovim 推荐的 vim.keymap.set）
local opts = { noremap = true, silent = true }

-- 保存和退出
vim.keymap.set("n", "q", ":q<CR>", opts)
vim.keymap.set("n", "s", ":w<CR>", opts)

-- 缓冲区切换
vim.keymap.set("n", "<leader>n", ":bn<CR>", opts)  -- 下一个缓冲区
vim.keymap.set("n", "<leader>m", ":bp<CR>", opts)  -- 上一个缓冲区（原来用 <leader>p 冲突了）

-- 行首行尾跳转（使用更合理的键位）
vim.keymap.set("n", "<leader>h", "^", opts)  -- 跳转到行首
vim.keymap.set("n", "<leader>l", "$", opts)  -- 跳转到行尾

-- 插入模式快速退出
vim.keymap.set("i", "jk", "<ESC>", opts)

-- 额外：如果你还想保留原来的 <leader>p 作为上一个缓冲区
-- 但 <leader>p 已经被 $ 占用，建议改用 <leader>m