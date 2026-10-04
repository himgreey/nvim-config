local M = {}
function M.setup()
    require("game.filetypes").setup()
    require("game.tasks").setup()
    require("game.keymaps").setup()
end
return M
