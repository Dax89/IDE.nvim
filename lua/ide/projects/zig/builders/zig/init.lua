local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")
local Cells = require("ide.ui.components.cells")

local Zig = Utils.class(Builder)
Zig.BUILD_MODES = {"debug", "release-safe", "release-small", "release-fast"}

function Zig:get_type()
    return "zig"
end

function Zig:on_ready()
    for _, m in ipairs(Zig.BUILD_MODES) do
        self.project:check_config(m, {mode = m})
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(Zig.BUILD_MODES[1])
    end

    self.project:check_runconfig(self.project:get_name(), { })

    if not self.project:get_selected_runconfig() then
        self.project:set_selected_runconfig(self.project:get_name())
    end

    self.project:write()
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
        self:check_and_run(Path:new(self.project:get_build_path(), self.project:get_name()), runconfig.cmdline, runconfig)
    end)
end

function Zig:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self, {
            {
                name = "mode", label = "Mode", type = Cells.SelectCell,
                items = function() return Zig.BUILD_MODES end
            },
            {name = "cmdline", label = "Command Line", type = Cells.InputCell},
        }):popup()
    end
end

return Zig


