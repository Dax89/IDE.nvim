local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")
local Cells = require("ide.ui.components.cells")

local Zig = Utils.class(Builder)
Zig.BUILD_MODES = {"debug", "release-safe", "release-small", "release-fast"}

function Zig:get_type()
    return "zig"
end

function Zig:get_steps()
    local buildzig = Path:new(self.project:get_path(), "build.zig")

    if not buildzig:is_file() then
        return { }
    end

    local PATTERN = [[b.step%(%s*"(.+)",%s*"(.+)"%s*%);]];
    local lines = Utils.read_lines(tostring(buildzig))
    local steps = { }

    for _, line in ipairs(lines) do
        local name, description = line:match(PATTERN)

        if name and description then
            table.insert(steps, {name = name, description = description})
        end
    end

    return steps
end

function Zig:_sync_runconfig()
    self.project:reset_runconfig()

    local steps = self:get_steps()

    for _, step in ipairs(steps) do
        self.project:check_runconfig(step.name, step)
    end

    if not vim.tbl_isempty(steps) and not self.project:get_selected_runconfig() then
        self.project:set_selected_runconfig(steps[1].name)
    end

    self.project:write()
end

function Zig:on_ready()
    for _, m in ipairs(Zig.BUILD_MODES) do
        self.project:check_config(m, {mode = m})
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(Zig.BUILD_MODES[1])
    end

    self:_sync_runconfig()
end

function Zig:create(data)
    local _, code = self.project:execute("zig", {"init-" .. data.template}, {src = true})

    if code ~= 0 then
        Utils.notify("Zig: Project creation failed", "error", {title = "ERROR"})
    end
end

function Zig:build(_, onexit)
    self:check_settings(function(_, config)
        local b = self.project:get_build_path()

        local args = {
            "build",
            "--prefix-exe-dir", Utils.get_filename(b)
        }

        if config.mode ~= "debug" then
            args = vim.list_extend(args, {"-D" .. config.mode .. "=true"})
        end

        b:parent():mkdir({parents = true, exists_ok = true})

        self.project:new_job("zig", args, {
            title = "Zig - Build",
            state = "build",
            onexit = onexit,
            src = true,
        })
    end)
end

function Zig:run()
    self:check_settings(function(_, _, runconfig)
        self:do_run_cmd({"zig", "build", runconfig.name}, runconfig, {src = true})
    end)
end

function Zig:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        self:_sync_runconfig()

        dlg(self, {
            runheader = {
                {name = "description", label = "Description", type = Cells.LabelCell},
            },
            showcommand = false,
            showarguments = false,
            showworkingdir = false,
            editable = false,
        }):popup()
    end
end

return Zig


