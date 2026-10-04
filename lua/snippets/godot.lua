local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
    s(
        "gdnode",
        fmt("extends {}\n\n\nfunc _ready() -> void:\n\t{}\n", { i(1, "Node"), i(0, "pass") })
    ),
    s("gdprocess", fmt("func _process(delta: float) -> void:\n\t{}", { i(0, "pass") })),
    s("gdphysics", fmt("func _physics_process(delta: float) -> void:\n\t{}", { i(0, "pass") })),
    s("gdsignal", fmt("signal {}({})", { i(1, "health_changed"), i(0, "value: int") })),
    s("gdexport", fmt("@export var {}: {} = {}", { i(1, "speed"), i(2, "float"), i(0, "5.0") })),
    s(
        "gdonready",
        fmt("@onready var {}: {} = ${}", { i(1, "sprite"), i(2, "Sprite2D"), i(0, "Sprite2D") })
    ),
}
