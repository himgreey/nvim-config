return {
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
        opts = {},
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "mason-org/mason.nvim" },
        cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
        opts = {
            ensure_installed = {
                "stylua",
                "csharpier",
                "netcoredbg",
                "codelldb",
                "tree-sitter-cli",
                {
                    "clang-format",
                    condition = function() return vim.fn.executable("clang-format") == 0 end,
                },
                {
                    "gdtoolkit",
                    condition = function() return vim.fn.executable("gdformat") == 0 end,
                },
            },
            run_on_start = false,
        },
    },
}
