local Utils = require("ide.utils")
local CProject = require("ide.projects.c")

local Cpp = Utils.class(CProject)

function Cpp:get_type()
    return "cpp"
end

return Cpp
