local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")

local Node = Utils.class(Builder)

function Node:get_type()
    return "node"
end

function Node:on_ready()
    local package = self:read_package()
    local defcfg = self.project:get_selected_runconfig()

    for name, command in pairs(package.scripts or { }) do
        local cfg = self.project:check_runconfig(name, {command = command})

        if not defcfg then
            defcfg = cfg
        end
    end

    if defcfg then
        self.project:set_selected_runconfig(defcfg.name)
    end

    self.project:write()
end

function Node:config_to_scripts()
    local package = self:read_package()
    package.scripts = { }

    for name, cfg in pairs(self.project:get_runconfig()) do
        package.scripts[name] = cfg.command
    end

    self:write_package(package)
end

function Node:create(data)
    local tdata = data.templatedata

    if tdata.command then
        self.project:execute_async(tdata.command.cmd, tdata.command.args, {src = true, log = false})
    else
        self.project:execute_async("npm", {"init", "-y"}, {src = true})

        local packagepath = Path:new(self.project:get_path(), "package.json")

        if not packagepath:is_file() then
            error("package.json not found")
        end

        local p = Utils.read_json(packagepath)
        p.name = data.name
        Utils.write_json(packagepath, p)
    end
end

function Node:build()
    self:do_run_cmd("npm", {"install"}, {
        title = "Building Node Package",
        src = true,
    })
end

function Node:run()
    local runcfg = self.project:get_selected_runconfig()
    self:do_run_cmd("npm", {"run", runcfg.name}, {src = true})
end

function Node:read_package()
    return Utils.read_json(Path:new(self.project:get_path(), "package.json"))
end

function Node:write_package(package)
    Utils.write_json(Path:new(self.project:get_path(), "package.json"), package)
end

return Node
