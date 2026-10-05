local M = {}
function M.setup()
    require("game.buffer").setup()
    require("game.filetypes").setup()
    require("game.tasks").setup()
    require("game.keymaps").setup()
    local project = require("game.project")
    vim.api.nvim_create_user_command("GameProjectRefresh", function()
        project.clear_cache()
        vim.notify("项目根目录缓存已刷新")
    end, {})
    vim.api.nvim_create_autocmd({ "DirChanged", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("GameProjectCache", { clear = true }),
        callback = function(args)
            local name = vim.fs.basename(args.file or "")
            if
                args.event == "DirChanged"
                or name == "project.godot"
                or name == "ProjectVersion.txt"
                or name == ".git"
                or name == "CMakeLists.txt"
                or name:match("%.uproject$")
                or name:match("%.slnx?$")
                or name:match("%.csproj$")
            then
                project.clear_cache()
            end
        end,
    })
end
return M
