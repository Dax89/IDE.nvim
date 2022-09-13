local Utils = require("ide.utils")
local Project = require("ide.base.project")

local Javascript = Utils.class(Project)

function Javascript:init(config, path, name, builder)
    Project.init(self, config, path, name, builder or "node")
end

function Javascript:get_type()
    return "javascript"
end

function Javascript.check(filepath, config)
    return Javascript.guess_project(filepath, "javascript", {
        patterns = {
            ["package.json"] = { builder = "node"}
        }
    }, config)
end

return Javascript
