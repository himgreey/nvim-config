local M = {}
function M.setup()
    vim.filetype.add({
        extension = {
            shader = "hlsl",
            hlsl = "hlsl",
            cginc = "hlsl",
            compute = "hlsl",
            uss = "css",
            uxml = "xml",
            meta = "yaml",
            unity = "yaml",
            prefab = "yaml",
            asset = "yaml",
            asmdef = "json",
            asmref = "json",
            gd = "gdscript",
            gdshader = "gdshader",
            gdshaderinc = "gdshader",
            tscn = "godot_resource",
            tres = "godot_resource",
            godot = "godot_resource",
            uproject = "json",
            uplugin = "json",
            usf = "hlsl",
            ush = "hlsl",
            glsl = "glsl",
        },
    })
    local group = vim.api.nvim_create_augroup("GameFiletypes", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "hlsl", "shader" },
        callback = function(args) vim.bo[args.buf].commentstring = "// %s" end,
    })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "gdscript", "gdshader", "cs", "csharp" },
        callback = function(args)
            local opts = vim.bo[args.buf]
            local tabs = opts.filetype == "gdscript" or opts.filetype == "gdshader"
            opts.expandtab = not tabs
            opts.shiftwidth, opts.tabstop, opts.softtabstop = 4, 4, tabs and 0 or 4
        end,
    })
end
return M
