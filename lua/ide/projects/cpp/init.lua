local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Cpp = Utils.class(Project)

function Cpp:get_type()
    return "cpp"
end

function Cpp.check(filepath, config)
    return Cpp.guess_project(filepath, "cpp",  {
        patterns = {
            ["CMakeLists.txt"] = { builder = "cmake"}
            -- ["Makefile"] = { builder = "make "},
        }
    }, config)
end

return Cpp
