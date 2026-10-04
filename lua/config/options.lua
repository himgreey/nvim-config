vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
for _, provider in ipairs({ "node", "perl", "python3", "ruby" }) do
    vim.g["loaded_" .. provider .. "_provider"] = 0
end
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local state = vim.fn.stdpath("state")
for _, name in ipairs({ "swap", "undo" }) do
    vim.fn.mkdir(state .. "/" .. name, "p")
end

local options = {
    directory = state .. "/swap//",
    undodir = state .. "/undo//",
    undofile = true,
    undolevels = 10000,
    backup = false,
    shiftwidth = 4,
    tabstop = 4,
    softtabstop = 4,
    expandtab = true,
    autoindent = true,
    smartindent = false,
    formatoptions = "qj",
    number = true,
    relativenumber = true,
    cursorline = true,
    cursorcolumn = true,
    ignorecase = true,
    smartcase = true,
    hlsearch = true,
    incsearch = true,
    autoread = true,
    confirm = true,
    history = 500,
    title = true,
    updatetime = 100,
    redrawtime = 1500,
    scrolloff = 8,
    sidescrolloff = 8,
    encoding = "utf-8",
    fileencoding = "utf-8",
    clipboard = "unnamedplus",
    mouse = "a",
    wrap = false,
    breakindent = true,
    linebreak = true,
    showmatch = true,
    splitright = true,
    splitbelow = true,
    laststatus = 3,
    cmdheight = 1,
    pumheight = 10,
    termguicolors = true,
    signcolumn = "yes",
    foldlevel = 99,
    showmode = false,
    showcmd = true,
    guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/LCursor,sm:block-blinkwait175-blinkoff150-blinkon175",
}
for name, value in pairs(options) do
    vim.opt[name] = value
end
