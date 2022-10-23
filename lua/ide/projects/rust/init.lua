local Utils = require("ide.utils")
local Project = require("ide.base.project")
local Path = require("plenary.path")

local Rust = Utils.class(Project)

function Rust:get_type()
    return "rust"
end

function Rust.get_templates()
    return {
        bin = {
            name = "Binary Application",
            default = true,
        },

        lib = {
            name = "Library",
        }
    }
end

function Rust:get_build_path(raw, name)
    local selcfg = self:get_selected_config()

    if not name and selcfg then
        name = selcfg.name
    end

    local p = Path:new(Project.get_path(self, false), "build", name)
    return raw and tostring(p) or p
end

function Rust.get_root_pattern()
    return {
        ["Cargo.toml"] = {builder = "cargo"}
    }
end

return Rust
