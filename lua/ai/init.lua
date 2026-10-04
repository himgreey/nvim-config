local M = {}
function M.setup()
    for lhs, name in pairs({ at = "codex", al = "claude" }) do
        vim.keymap.set(
            "n",
            "<leader>" .. lhs,
            function() require("ai.tools").terminal(name) end,
            { desc = name .. " 终端" }
        )
    end
    for _, mode in ipairs({ "n", "v" }) do
        vim.keymap.set(
            mode,
            "<leader>ay",
            function() require("ai.tools").copy(mode == "v") end,
            { desc = "复制代码和诊断给 AI" }
        )
    end
end
return M
