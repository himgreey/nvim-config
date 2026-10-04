local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        "gdfragment",
        fmt(
            "shader_type {};\n\nvoid fragment() {{\n\t{}\n}}",
            { i(1, "canvas_item"), i(0, "COLOR = vec4(1.0);") }
        )
    ),
}
