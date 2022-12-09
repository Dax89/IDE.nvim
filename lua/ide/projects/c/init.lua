local Utils = require("ide.utils")
local Project = require("ide.base.project")

local C = Utils.class(Project)

function C:get_type()
    return "c"
end

function C.get_root_pattern()
    return {
        ["CMakeLists.txt"] = {builder = "cmake"}
        -- ["Makefile"] = { builder = "make "},
    }
end

return C
