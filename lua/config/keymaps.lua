local map = vim.keymap.set
local keys = {
    { "n", "s", "<cmd>write<CR>", "保存文件" },
    { "n", "<leader>q", "<cmd>quit<CR>", "退出窗口" },
    { "n", "<leader>Q", "<cmd>quit!<CR>", "强制退出窗口" },
    { "n", "<leader>sq", "<cmd>wq<CR>", "保存并退出" },
    { "n", "<leader>bn", "<cmd>bnext<CR>", "下一个 buffer" },
    { "n", "<leader>bp", "<cmd>bprevious<CR>", "上一个 buffer" },
    { "n", "<leader>bd", "<cmd>bdelete<CR>", "关闭 buffer" },
    { "n", "<leader>h", "^", "跳到行首" },
    { "n", "<leader>l", "$", "跳到行尾" },
    { "n", "<Esc>", "<cmd>nohlsearch<CR>", "清除搜索高亮" },
    { "i", "jk", "<Esc>", "退出插入模式" },
    { "v", "<", "<gv", "减少缩进并保持选中" },
    { "v", ">", ">gv", "增加缩进并保持选中" },
    { "v", "J", ":m '>+1<CR>gv=gv", "向下移动选中行" },
    { "v", "K", ":m '<-2<CR>gv=gv", "向上移动选中行" },
    { "t", "<Esc><Esc>", "<C-\\><C-n>", "退出终端输入模式" },
}
for _, key in ipairs(keys) do
    map(key[1], key[2], key[3], { silent = true, desc = key[4] })
end
for _, direction in ipairs({ "h", "j", "k", "l" }) do
    map("n", "<C-" .. direction .. ">", "<C-w>" .. direction, { desc = "切换窗口" })
    map("t", "<C-" .. direction .. ">", "<C-\\><C-n><C-w>" .. direction, { desc = "切换窗口" })
end
