local Utils = require("ide.utils")
local Project = require("ide.base.project")
local Path = require("plenary.path")

local Lua = Utils.class(Project)

function Lua:get_type()
    return "lua"
end

function Lua.get_root_pattern()
    return function(fp)
        local p = Path:new(fp)
        local luapath, pluginpath = Path:new(p, "lua"), Path:new(p, "plugin")
        return luapath:is_dir() and pluginpath:is_dir()
    end
end

return Lua
