local M = {}
function M.setup()
    local ls = require("luasnip")
    for ft, module in pairs({
        cs = "unity",
        gdscript = "godot",
        cpp = "unreal",
        gdshader = "shaders",
    }) do
        ls.add_snippets(ft, require("snippets." .. module), { key = "game-" .. ft })
    end
end
return M
