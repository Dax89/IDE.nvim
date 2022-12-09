local Utils = require("ide.utils")
local Async = require("plenary.async")
local Path = require("plenary.path")
local Runner = require("ide.base.runner")
local Scan = require("plenary.scandir")
local Log = require("ide.log")

local Project = Utils.class(Runner)

function Project:init(config, path, name, builder)
    Runner.init(self, config)

    if Utils.get_filename(path) ~= name then
        path = Path:new(path, name)
        path:mkdir()
    end

    self.path = tostring(path)

    self.data = {
        name = name,
        type = self:get_type(),
        mode = nil,
        target = nil,
        builder = builder,
        vars = { },
        config = { },
        runconfig = { },
        selconfig = nil,
        selrunconfig = nil,
    }

    local projfile = Path:new(self.path, config.project_file)

    if projfile:is_file() then
        local nvide = Utils.read_json(projfile)

        if nvide then
            self.data = vim.tbl_extend("force", self.data, nvide)
        end
    end

    if builder then
        local ok, BuilderType = pcall(require, "ide.projects." .. self:get_type() .. ".builders." .. builder)

        if ok then
            Log.debug("Project: Loading '" .. self:get_name() .. "', type: '" .. self:get_type() .. "', builder: '" .. builder .. "'")
        else
            error(BuilderType)
        end

        self.builder = BuilderType(self)
    else
        if self:is_virtual() then
            Log.debug("Project: Loading '" .. self:get_name() .. "', type: *VIRTUAL*, builder: 'nvide'")
        else
            Log.debug("Project: Loading '" .. self:get_name() .. "', type: '" .. self:get_type() .. "', builder: 'nvide'")
        end
        self.builder = require("ide.base.builder")(self)
    end
end

function Project:execute_async(command, args, options)
    options = options or { }
    return self:_execute_async(command, args, options.src and self:get_path(true) or self:get_build_path(true), options)
end

function Project:execute(command, args, options)
    options = options or { }

    local cwd = vim.F.if_nil(options.cwd, options.src and self:get_path(true) or self:get_build_path(true))
    return self:_execute(command, args, cwd, options)
end

function Project:create(createmodel, ondone)
    if type(createmodel.template) == "string" then
        self:untemplate(createmodel.template, createmodel:get_data())
    end

    if self.builder then
        self.builder:create(createmodel, function()
            Utils.if_call(ondone)
            self:save()
        end)
    elseif vim.is_callable(ondone) then
        Utils.if_call(ondone)
    end
end

function Project:get_name()
    return self.data.name
end

function Project:get_type()
    return nil
end

function Project:get_selected_config()
    return self.data.config[self.data.selconfig]
end

function Project:get_selected_runconfig()
    return self.data.runconfig[self.data.selrunconfig]
end

function Project:set_selected_config(v)
    if self.data.selconfig and self.data.config[self.data.selconfig] then
        self.data.config[self.data.selconfig].selected = false
    end

    if self.data.config[v] == nil then
        error("Configuration '" .. v .. "' not found")
    elseif self.data.selconfig ~= v then
        self.data.config[v].selected = true
        self.data.selconfig = v
        return true
    end

    return false
end

function Project:set_selected_runconfig(v)
    if self.data.selconfig and self.data.runconfig[self.data.selrunconfig] then
        self.data.runconfig[self.data.selrunconfig].selected = false
    end

    if self.data.runconfig[v] == nil then
        error("Run Configuration '" .. v .. "' not found")
    elseif self.data.selrunconfig ~= v then
        self.data.runconfig[v].selected = true
        self.data.selrunconfig = v
        return true
    end

    return false
end

function Project:_check_config(gconfig, name, config)
    if gconfig[name] == nil then
        self:_set_config(gconfig, name, config)
    end

    return gconfig[name]
end

function Project:_project_filepath()
    return Path:new(self:get_path(true), self.config.project_file)
end

function Project:_has_project_file()
    return self:_project_filepath():exists()
end

function Project:check_config(name, config)
    return self:_check_config(self.data.config, name, config)
end

function Project:check_runconfig(name, config)
    return self:_check_config(self.data.runconfig, name, config)
end

function Project:reset_config()
    self.data.config = { }
    self.data.selconfig = nil
end

function Project:reset_runconfig()
    self.data.runconfig = { }
    self.data.selrunconfig = nil
end

function Project:_get_config(gconfig, name)
    vim.validate({
        name = {name, {"string", "nil"}},
    })

    return name == nil and gconfig or gconfig[name]
end

function Project:_set_config(gconfig, name, config)
    vim.validate({
        name = {name, "string"},
        config = {config, {"table", "nil"}},
    })

    config = vim.F.if_nil(config, { })
    config.name = name
    gconfig[name] = config
end

function Project:get_config(name)
    return self:_get_config(self.data.config, name)
end

function Project:set_config(name, config, reset)
    self:_set_config(self.data.config, name, config)

    if reset == true then
        self.data.config = { }
        self.data.selconfig = nil
    end
end

function Project:get_runconfig(name)
    return self:_get_config(self.data.runconfig, name)
end

function Project:set_runconfig(name, config, reset)
    self:_set_config(self.data.runconfig, name, config)

    if reset == true then
        self.data.runconfig = { }
        self.data.selrunconfig = nil
    end
end

function Project:is_virtual()
    return self:get_type() == nil
end

function Project:set_var(k, v)
    self.data.vars[k] = v
end

function Project:get_var(k)
    return self.data.var[k]
end

function Project:get_template_path()
    return Project._get_template_path(self.data.type, self.data.builder)
end

function Project:get_path(raw)
    return raw and self.path or Path:new(self.path)
end

function Project:get_build_path(raw, name)
    local p, selcfg = nil, self:get_selected_config()

    if not name and selcfg then
        name = selcfg.name
    end

    if self.config.shadow_build then
        if name then
            p = Path:new(self:get_path(), "..", "build_" .. self.data.name .. "_" .. name)
        else
            p = Path:new(self:get_path(), "..", "build_" .. self.data.name)
        end
    else
        if name then
            p = Path:new(self:get_path(), "build" .. "_" .. name)
        else
            p = Path:new(self:get_path(), "build")
        end
    end

    return raw and tostring(p) or p
end

function Project.get_root_pattern()
    return nil
end

function Project._get_template_path(type, builder)
    local templatepath = Path:new(Utils.get_plugin_root(), "templates", type, builder)
    return templatepath:is_dir() and templatepath or nil
end

function Project.get_templates(t, b)
    local templates, templatepath = { }, Project._get_template_path(t, b)

    if templatepath then
        for _, p in ipairs(Scan.scan_dir(tostring(templatepath), {only_dirs = true, depth = 1})) do
            local templatedata, templatefile = { }, Path:new(p, "template.nvide")

            if templatefile:is_file() then
                templatedata = Utils.read_json(templatefile)
            else
                templatedata = { }
            end

            local id = Utils.get_filename(p)
            templatedata.path = p
            templatedata.name = templatedata.name or id
            templates[id] = templatedata
        end
    end

    return templates
end

function Project:untemplate(template, createdata)
    local tp = Path:new(self:get_template_path(), template)

    if not tp then
        Log.debug("Project.untemplate(): No templates available");
        return
    end

    Log.debug("Project.untemplate(): Processing templates from " .. tostring(tp))

    tp:copy({
        destination = self:get_path(),
        recursive = true
    })

    for _, p in ipairs(Scan.scan_dir(self:get_path(true), {add_dirs = false})) do
        local t = Utils.read_file(p)

        for k, v in pairs(createdata) do
            t = t:gsub(":" .. k .. ":", tostring(v))
        end

        Utils.write_file(p, t)
    end

    local templatefile = Path:new(self:get_path(), "template.nvide")

    if templatefile:is_file() then
        templatefile:rm()
    end
end

function Project:configure()
    if not self:has_state("configure") and not self:has_state("build") and self.builder then
        self:save()
        Async.run(function()
            self.builder:configure()
        end)
    end
end

function Project:stop()
    if vim.tbl_isempty(self.jobs) then
        return
    end

    -- NOTE: Kill Workaround -> https://github.com/nvim-lua/plenary.nvim/issues/156
    if #self.jobs == 1 then
        vim.loop.kill(self.jobs[1][1].pid, 9)
        return
    end

    vim.ui.select(self.jobs, {
        prompt = "Stop Job",
        format_item = function(job)
            if job[2].title then
                return tostring(job[1].pid) .. ": " .. job[2].title
            end

            return tostring(job[1].pid) .. ": " .. job[1].command .. " " .. table.concat(job[1].args, " ")
        end
    }, function(choice)
        if choice then
            vim.loop.kill(choice[1].pid, 9)
        end
    end)
end

function Project:build()
    if not self:has_state("build") and self.builder then
        self:save()
        Async.run(function()
            self.builder:build()
        end)
    end
end

function Project:run()
    if self.builder then
        self:save()
        Async.run(function()
            self.builder:run()
        end)
    end
end

function Project:debug(options)
    if self.builder then
        self:save()
        Async.run(function()
            self.builder:debug(options)
        end)
    end
end

function Project:settings()
    if self.builder then
        Async.run(function()
            self.builder:settings()
        end)
    end
end

function Project:save()
    if self:get_type() then
        vim.api.nvim_command("silent! wall")
        self:write()
    end
end

function Project:write(force)
    if self:get_type() and (force == true or (self.config.auto_save == true or self:_has_project_file())) then
        Utils.write_json(Path:new(self:get_path(true), self.config.project_file), self.data)
    end
end

function Project:run_dap(dapoptions, options)
    options = options or { }

    local Dap = require("dap")

    local DAP_COMMANDS = {
        stop = function()
            Dap.disconnect()
        end,
        stepover = function()
            Dap.step_over()
        end,
        stepinto = function()
            Dap.step_into()
        end
    }

    if self:has_state("debug") then
        if vim.is_callable(DAP_COMMANDS[options.type]) then
            DAP_COMMANDS[options.type]()
        else
            Dap.continue()
        end
    else
        Dap.run(vim.tbl_extend("force", {
            name = self.data.name,
            cwd = vim.F.if_nil(options.cwd, self:get_build_path(true))
        }, dapoptions), {
            before = function(config)
                self:set_state("debug")
                return config
            end,
            after = function()
                self:unset_state("debug")
            end,
        })
    end
end

function Project:_select_config(title, config, cb)
    vim.ui.select(vim.tbl_keys(config), {
        prompt = title,
        format_item = function(item)
            vim.pretty_print(config[item])
            if config[item].selected then
                return item .. " - SELECTED"
            end

            return item
        end
    }, function(choice)
        if choice and vim.is_callable(cb) then
            cb(choice)
        end
    end)
end

function Project:select_config()
    return self:_select_config("Select Config", self.data.config, function(cfg)
        if not self:set_selected_config(cfg) then
            return
        end

        if self.builder then
            self.builder:on_config_changed(self.data.config[cfg])
        end
    end)
end

function Project:select_runconfig()
    return self:_select_config("Select Run Config", self.data.runconfig, function(cfg)
        if not self:set_selected_runconfig(cfg) then
            return
        end

        if self.builder then
            self.builder:on_runconfig_changed(self.data.runconfig[cfg])
        end
    end)
end

function Project:on_ready()
    if self.builder then
        Async.run(function()
            self.builder:on_ready()
        end)
    end
end

function Project:open_buildpath()
    local p = self:get_build_path()

    if p:exists() then
        Utils.os_open(p)
    end
end

function Project:open_sourcepath()
    local p = self:get_path()

    if p:exists() then
        Utils.os_open(p)
    end
end

return Project

