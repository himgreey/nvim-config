local M = {}
function M.setup()
    local map = vim.keymap.set
    local commands =
        { pb = "GameBuild", pr = "GameRun", pe = "GameEditor", pt = "GameTest", pi = "GameInfo" }
    for lhs, command in pairs(commands) do
        map("n", "<leader>" .. lhs, "<cmd>" .. command .. "<CR>", { desc = command })
    end
    map(
        "n",
        "<leader>pc",
        function() vim.cmd.tcd(vim.fn.fnameescape(require("game.project").detect().root)) end,
        { desc = "切换到项目根目录" }
    )
    map(
        "n",
        "<leader>ub",
        function() require("game.tasks").dotnet_build() end,
        { desc = "构建 .NET 项目" }
    )
    map("n", "<leader>ut", function() require("game.tasks").test() end, { desc = "Unity 测试" })
    map(
        "n",
        "<leader>uo",
        function() require("game.tasks").run(true) end,
        { desc = "打开引擎编辑器" }
    )
    map(
        "n",
        "<leader>um",
        function() require("game.unity").open("meta") end,
        { desc = "Unity：切换 meta" }
    )
    map(
        "n",
        "<leader>ua",
        function() require("game.unity").open("test") end,
        { desc = "Unity：切换 Test.cs" }
    )
end
return M
