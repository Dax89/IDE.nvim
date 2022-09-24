local Utils = require("ide.utils")
local Path = require("plenary.path")
local Runner = require "ide.base.runner"

local Project = Utils.class(Runner)

function Project:init(config, path, name, builder)
    Runner.init(self, config)

    if vim.fn.fnamemodify(tostring(path), ":t") ~= name then
        path = Path:new(path, name)
        path:mkdir()
    end

    self.path = tostring(path)

    self.data = {
        name = name,
        type = self:get_type(),
        mode = nil,
        builder = builder,
        options = { }
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

        if not ok then
            error("Builder '" .. builder .. "' not found")
        end

        self.builder = BuilderType(self)
    end

    if self.config.auto_create then
        self:save()
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

function Project:create()
    self:untemplate()

    if self.builder then
        self.builder:create()
    end

    self:save()
end

function Project:get_name()
    return self.data.name
end

function Project:get_type()
    return nil
end

function Project:is_virtual()
    return self:get_type() == nil
end

function Project.check(filepath, config)
    return Project.guess_project(filepath, nil, {
        patterns = vim.list_extend({config.project_file}, config.root_patterns)
    }, config)
end

function Project:set_option(k, v)
    self.data.options[k] = v
end

function Project:get_option(k)
    return self.data.options[k]
end

function Project:set_mode(m)
    self.data.mode = m
end

function Project:get_mode()
    return self.data.mode
end

function Project:get_template_path()
    local templatepath = Path:new(Utils.get_plugin_root(), "templates", self.data.type)
    return templatepath:is_dir() and templatepath or nil
end

function Project:get_path(raw)
    return raw and self.path or Path:new(self.path)
end

function Project:get_build_path(raw)
    local p = nil

    if self.config.shadow_build then
        if self:get_mode() then
            p = Path:new(self:get_path(), "..", "build_" .. self.data.name .. "_" .. self:get_mode())
        else
            p = Path:new(self:get_path(), "..", "build_" .. self.data.name)
        end
    else
        if self:get_mode() then
            p = Path:new(self:get_path(), "build", self:get_mode())
        else
            p = Path:new(self:get_path(), "build")
        end
    end

    assert(p ~= nil)
    return raw and tostring(p) or p
end

function Project._check_pattern(path, pattern)
    local isdir = vim.endswith(pattern, "/")
    local n = isdir and pattern:gsub(0, -2) or pattern
    local p = Path:new(path, n)
    return isdir and p:is_dir() or p:is_file()
end

function Project._find_pattern_in_fs(filepath, options)
    local patterns = vim.tbl_islist(options.patterns) and options.patterns or vim.tbl_keys(options.patterns)

    for _, pattern in ipairs(patterns) do
        if Project._check_pattern(filepath, pattern) then
            return pattern
        end
    end

    return nil
end

function Project._find_root_in_fs(filepath, options)
    for _, cp in ipairs(filepath:parents()) do
        if Project._find_pattern_in_fs(cp, options) then
            return tostring(cp)
        end
    end

    return tostring(filepath)
end

function Project.guess_project(filepath, type, options, config)
    local p = Path:new(tostring(filepath))

    -- Check if is a GIT Submodule
    local gitroot, ret = Utils.os_execute("git", {"rev-parse", "--show-superproject-working-tree"}, tostring(p))

    -- Check if is a GIT Repo
    if ret == 0 and vim.tbl_isempty(gitroot) then
        gitroot, ret = Utils.os_execute("git", {"rev-parse", "--show-toplevel"}, tostring(p))
    end

    if ret ~= 0 or vim.tbl_isempty(gitroot) then
        p = Project._find_root_in_fs(filepath, options)
    else
        p = gitroot[1]
    end

    assert(p, "Invalid project root")
    local pattern = Project._find_pattern_in_fs(p, options)

    if not pattern then
        return nil
    end

    local name = vim.fn.fnamemodify(p, ":t")
    local projfile = Path:new(p, config.project_file)

    if projfile:is_file() then
        local nvide = Utils.read_json(projfile)

        if nvide.type ~= type then
            return nil
        end

        name = nvide.name
    end

    return vim.tbl_extend("force", {
        name = name,
        root = p
    }, options.patterns[pattern] or { })
end

function Project:untemplate()
    local tp = self:get_template_path()

    if not tp then
        return
    end

    tp:copy({
        destination = self:get_path(),
        recursive = true
    })

    local data = {
        projectname = self.data.name
    }

    for _, p in ipairs(require("plenary.scandir").scan_dir(self:get_path(true), {add_dirs = false})) do
        local t = Utils.read_file(p)

        for k, v in pairs(data) do
            t = t:gsub(":" .. k .. ":", v)
        end

        Utils.write_file(p, t)
    end
end

function Project:configure()
    if self.builder then
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
    if self.builder then
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
        if options.type then
            vim.F.npcall(DAP_COMMANDS[options.type])
        else
            Dap.continue()
        end
    else
        Dap.run(vim.tbl_extend("force", {
            name = self.data.name,
            cwd = self:get_build_path(true)
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
