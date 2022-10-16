local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")

local Node = Utils.class(Builder)

function Node:get_type()
    return "node"
end

function Node:on_ready()
    local package = self:read_package()
    local defcfg = self.project:get_selected_config()

    for name, command in pairs(package.scripts or { }) do
        local cfg = self.project:check_config(name, {command = command})

        if not defcfg then
            defcfg = cfg
        end
    end

    if defcfg then
        self.project:set_selected_config(defcfg.name)
    end

    self.project:write()
end

function Node:config_to_scripts()
    local package = self:read_package()
    package.scripts = { }

    for name, cfg in pairs(self.project:get_config()) do
        package.scripts[name] = cfg.command
    end

    self:write_package(package)
end

function Node:create(data)
    self.project:execute("npm", {"init", "-y"}, {src = true})

    local packagepath = Path:new(self.project:get_path(), "package.json")

    if not packagepath:is_file() then
        error("package.json not found")
    end

    local p = Utils.read_json(packagepath)
    p.name = data.name
    Utils.write_json(packagepath, p)
end

function Node:run()
    self:check_settings(function(_, config)
        self:do_run_cmd(config.command, config, {src = true})
    end)
end

function Node:read_package()
    return Utils.read_json(Path:new(self.project:get_path(), "package.json"))
end

function Node:write_package(package)
    Utils.write_json(Path:new(self.project:get_path(), "package.json"), package)
end

return Node
