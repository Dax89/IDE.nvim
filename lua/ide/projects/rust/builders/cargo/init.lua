local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")
local Cells = require("ide.ui.components.cells")

local Cargo = Utils.class(Builder)
Cargo.BUILD_MODES = {"debug", "release", "test", "bench"} -- https://doc.rust-lang.org/cargo/reference/profiles.html

function Cargo:get_manifest()
    return self.project:execute("cargo", {"read-manifest"}, {json = true, src = true})
end

function Cargo:get_type()
    return "cargo"
end

function Cargo:on_ready()
    local hasdefaulttarget = vim.tbl_contains(self:get_targets(), self.project:get_name())

    for _, m in ipairs(Cargo.BUILD_MODES) do
        self.project:check_config(m, {
            mode = m,
            cwd = self.project:get_build_path(true, m),
            target = hasdefaulttarget and self.project:get_name() or nil
        })
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(Cargo.BUILD_MODES[1])
    end

    self.project:write()
end

function Cargo:create()
    local _, code = self.project:execute("cargo", {"init", "--name", self.project:get_name(), self.project:get_path(true)}, {src = true})

    if code ~= 0 then
        Utils.notify("Cargo: Project creation failed", "error", {title = "ERROR"})
    end
end

function Cargo:get_targets()
    local m = self:get_manifest()

    return vim.tbl_map(function(t)
        return t.name
    end, m.targets)
end

function Cargo:build(_, onexit)
    self:check_settings(function(_, config)
        local b = self.project:get_build_path()

        local args = {
            "build",
            "--target-dir", tostring(b:parent())
        }

        if config.mode == "release" then
            args = vim.list_extend(args, {"-r"})
        end

        if config.mode ~= "debug" then
            args = vim.list_extend(args, {"--profile", config.mode})
        end

        b:mkdir({parents = true, exists_ok = true})

        self.project:new_job("cargo", args, {
            title = "Cargo - Build",
            state = "build",
            onexit = onexit,
        })
    end)
end

function Cargo:run()
    self:check_settings(function(_, config)
        self:check_and_run(Path:new(self.project:get_build_path(true), config.target), config.cmdline, config)
    end)
end

function Cargo:debug(options)
    self:check_settings(function(_, config)
        self.project:run_dap({
            request = "launch",
            type = "codelldb",
            program = tostring(Path:new(self.project:get_build_path(true), config.target)),
            args = config.cmdline,
        }, options or { })
    end)
end

function Cargo:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self, {
            {
                name = "mode", label = "Mode", type = Cells.SelectCell,
                items = function() return self:get_modes() end
            },
            {
                name = "target", label = "Target", type = Cells.SelectCell,
                items = function() return self:get_targets() end
            },
            {name = "cmdline", label = "Command Line", type = Cells.InputCell},
            {name = "cwd", label = "Working Dir", type = Cells.PickerCell},
        }):popup()
    end
end

return Cargo

