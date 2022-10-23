local Utils = require("ide.utils")
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
        selconfig = nil,
        config = { },
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
            error("Builder '" .. builder .. "' not found")
        end

        self.builder = BuilderType(self)
    end
end

function Project:execute(command, args, options)
    options = options or { }
    return self:_execute(command, args, options.src and self:get_path(true) or self:get_build_path(true), options)
end

function Project:new_job(command, args, options)
    options = options or { }
    return self:_new_job(command, args, options.src and self:get_path(true) or self:get_build_path(true), options)
end

function Project:create(createmodel)
    if type(createmodel.template) == "string" then
        self:untemplate(createmodel.template, createmodel:get_data())
    end

    if self.builder then
        self.builder:create(createmodel)
    end

    self:save()
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

function Project:set_selected_config(v)
    if self.data.config[v] == nil then
        error("Configuration '" .. v .. "' not found")
    else
        self.data.selconfig = v
    end
end

function Project:check_config(name, config)
    if self.data.config[name] == nil then
        self:set_config(name, config)
    end

    return self.data.config[name]
end

function Project:set_config(name, config)
    vim.validate({
        name = {name, "string"},
        config = {config, {"table", "nil"}},
    })

    config.name = name
    self.data.config[name] = config
end

function Project:get_config(name)
    vim.validate({
        name = {name, {"string", "nil"}},
    })

    return name == nil and self.data.config or self.data.config[name]
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
        self.builder:configure()
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
        self.builder:build()
    end
end

function Project:run()
    if self.builder then
        self:save()
        self.builder:run()
    end
end

function Project:debug(options)
    if self.builder then
        self:save()
        self.builder:debug(options)
    end
end

function Project:settings()
    if self.builder then
        self.builder:settings()
    end
end

function Project:save()
    if self:get_type() then
        vim.api.nvim_command("silent! wall")
        self:write()
    end
end

function Project:write()
    if self:get_type() then
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

function Project:on_ready()
    if self.builder then
        self.builder:on_ready()
    end
end

return Project

