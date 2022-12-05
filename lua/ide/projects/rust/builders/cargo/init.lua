local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")
local Cells = require("ide.ui.components.cells")

local Cargo = Utils.class(Builder)
Cargo.BUILD_MODES = {"debug", "release", "test", "bench"} -- https://doc.rust-lang.org/cargo/reference/profiles.html

function Cargo:get_manifest()
    return self.project:execute_async("cargo", {"read-manifest"}, {json = true, src = true})
end

function Cargo:get_type()
    return "cargo"
end

function Cargo:on_ready()
    for _, m in ipairs(Cargo.BUILD_MODES) do
        self.project:check_config(m, {mode = m})
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(Cargo.BUILD_MODES[1])
    end

    local targets = self:get_targets()

    for _, tgt in ipairs(targets) do
        self.project:check_runconfig(tgt, {target = tgt})
    end

    if not vim.tbl_isempty(targets) and not self.project:get_selected_runconfig() then
        self.project:set_selected_runconfig(targets[1])
    end

    self.project:write()
end

function Cargo:create(data)
    local _, code = self.project:execute_async("cargo", {"init", "--" .. data.template, "--name", self.project:get_name(), self.project:get_path(true)}, {src = true})

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

function Cargo:get_executable_filepath(runconfig)
    return Path:new(self.project:get_build_path(), runconfig.target)
end

function Cargo:build()
    local s = self:check_settings()

    if s then
        local b = self.project:get_build_path()

        local args = {
            "build",
            "--target-dir", tostring(b:parent())
        }

        if s.config.mode == "release" then
            args = vim.list_extend(args, {"-r"})
        end

        if s.config.mode ~= "debug" then
            args = vim.list_extend(args, {"--profile", s.config.mode})
        end

        b:mkdir({parents = true, exists_ok = true})

        self.project:execute_async("cargo", args, {
            title = "Cargo - Build",
            state = "build",
        })
    end
end

function Cargo:run()
    local s = self:check_settings()

    if s then
        self:do_run(self:get_executable_filepath(s.runconfig), s.runconfig.cmdline)
    end
end

function Cargo:debug(options)
    local s = self:check_settings()

    if s then
        self.project:run_dap({
            request = "launch",
            type = "codelldb",
            program = tostring(self:get_executable_filepath(s.runconfig)),
            args = s.config.cmdline,
        }, options or { })
    end
end

function Cargo:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self, {
            {
                name = "mode", label = "Mode", type = Cells.SelectCell,
                items = function() return Cargo.BUILD_MODES end
            },
            {
                name = "target", label = "Target", type = Cells.SelectCell,
                items = function() return self:get_targets() end
            },
            {name = "cmdline", label = "Command Line", type = Cells.InputCell},
        }):popup()
    end
end

return Cargo

