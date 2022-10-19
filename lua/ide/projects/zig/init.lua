local Utils = require("ide.utils")
local Project = require("ide.base.project")
local Path = require("plenary.path")

local Zig = Utils.class(Project)

function Zig:get_type()
    return "zig"
end

function Zig.get_templates()
    return {
        exe = {
            name = "Executable",
            default = true,
        },

        lib = {
            name = "Library",
        }
    }
end

function Zig:get_build_path(raw, name)
    local selcfg = self:get_selected_config()

    if not name and selcfg then
        name = selcfg.name
    end

    local p = Path:new(self:get_path(), "zig-out", name)
    return raw and tostring(p) or p
end

function Zig.check(filepath, config)
    return Zig.guess_project(filepath, "zig", {
        patterns = {
            ["build.zig"] = {builder = "zig"}
        }
    }, config)
end

return Zig
