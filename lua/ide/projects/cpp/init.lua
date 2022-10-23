local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Cpp = Utils.class(Project)

function Cpp:get_type()
    return "cpp"
end

function Cpp.get_root_pattern()
    return {
        ["CMakeLists.txt"] = {builder = "cmake"}
        -- ["Makefile"] = { builder = "make "},
    }
end

return Cpp
