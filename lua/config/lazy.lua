local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
    local result = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        path,
    })
    if vim.v.shell_error ~= 0 then error("Lazy.nvim 安装失败：\n" .. result) end
end
vim.opt.rtp:prepend(path)

require("lazy").setup({
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.coding" },
    { import = "plugins.debug" },
    { import = "plugins.git" },
    { import = "plugins.game" },
    { import = "plugins.ai" },
}, {
    defaults = { lazy = true, version = false },
    install = { colorscheme = { "catppuccin" } },
    checker = { enabled = true, frequency = 86400 },
    change_detection = { notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "gzip",
                "matchit",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
            },
        },
    },
    ui = { border = "rounded", size = { width = 0.8, height = 0.8 }, title = "Lazy.nvim" },
})
