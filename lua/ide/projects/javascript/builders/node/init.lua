local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")

local Node = Utils.class(Builder)

function Node:create()
    self.project:execute("npm", {"init", "-y"}, {src = true})

    local packagepath = Path:new(self.project:get_path(), "package.json")

    if not packagepath:is_file() then
        error("package.json not found")
    end

    local p = Utils.read_json(packagepath)
    p.name = self.project:get_name()
    Utils.write_json(packagepath, p)
end

function Node:settings()
end

return Node
