local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Rust = Utils.class(Project)

function Rust:get_type()
    return "rust"
end

function Rust.check(filepath, config)
    return Rust.guess_project(filepath, "rust", {
        patterns = {
            ["Cargo.toml"] = {builder = "cargo"}
        }
    }, config)
end

return Rust
