local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Javascript = Utils.class(Project)

function Javascript:get_type()
    return "javascript"
end

function Javascript.get_root_pattern()
    return {
        ["package.json"] = {builder = "node"}
    }
end

return Javascript
