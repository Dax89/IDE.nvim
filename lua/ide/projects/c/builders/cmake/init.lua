local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")
local Cells = require("ide.ui.components.cells")

local CMake = Utils.class(Builder)
CMake.BUILD_MODES = {"Debug", "Release", "RelWithDebInfo", "MinSizeRel"}
CMake.API_VERSION = "v1"

function CMake:get_type()
    return "cmake"
end

function CMake:on_config_changed(_)
    self:configure()
end

function CMake:on_ready()
    self:_configure(CMake.BUILD_MODES[1])

    for _, m in ipairs(CMake.BUILD_MODES) do
        self.project:check_config(m, {mode = m})
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(CMake.BUILD_MODES[1])
    end

    local targets = self:get_targets(CMake.BUILD_MODES[1])

    for _, tgt in ipairs(targets) do
        self.project:check_runconfig(tgt, {target = tgt})
    end

    if not vim.tbl_isempty(targets) and not self.project:get_selected_runconfig() then
        self.project:set_selected_runconfig(targets[1])
    end

    self.project:write()
end

function CMake:_write_query(q, mode)
    local p = Path:new(self.project:get_build_path(false, mode), ".cmake", "api", CMake.API_VERSION, "query")
    p:mkdir({parents = true, exists_ok = true})
    Path:new(p, q):touch()
end

function CMake:_read_query(q, mode)
    local p = Path:new(self.project:get_build_path(false, mode), ".cmake", "api", CMake.API_VERSION, "reply")

    for _, f in ipairs(require("plenary.scandir").scan_dir(tostring(p), {add_dirs = false, depth = 1})) do
        if vim.startswith(Utils.get_filename(f), q) then
            return Utils.read_json(f)
        end
    end

    return nil
end

function CMake:get_modes()
    return CMake.BUILD_MODES
end

function CMake:get_targets(mode, type)
    mode = vim.F.if_nil(mode, self.project:get_selected_config().mode)
    type = vim.F.if_nil(type, "EXECUTABLE")

    local codemodel = self:_read_query("codemodel-v2", mode)

    if codemodel and codemodel.configurations and not vim.tbl_isempty(codemodel.configurations) then
        local targets = vim.tbl_filter(function(x)
            local targetdata = self:_read_query("target-" .. x.name)
            return targetdata and targetdata.type == type
        end, codemodel.configurations[1].targets)

        return vim.tbl_map(function(x)
            return x.name
        end, targets)
    end

    return {}
end

function CMake:_configure(mode)
    self:_write_query("codemodel-v2", mode)

    if not mode then
        mode = self.project:get_selected_config().mode
    end

    self.project:execute_async("cmake", {
        "-B", self.project:get_build_path(true, mode),
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_BUILD_TYPE=" .. mode,
    }, {title = "CMake - Configure", src = true, state = "configure"})

    local compilecommands = Path:new(self.project:get_build_path(), "compile_commands.json")

    if compilecommands:is_file() then
        compilecommands:copy({destination = Path:new(self.project:get_path(), "compile_commands.json" )})
    end
end

function CMake:get_executable_filepath(runconfig)
    local targetdata = self:_read_query("target-" .. runconfig.target)

    if targetdata then
        return Path:new(self.project:get_build_path(true), targetdata.artifacts[1].path)
    end

    return nil
end

function CMake:configure()
    Builder.configure(self)
    self:_configure()
end

function CMake:build()
    local s = self:check_settings()

    if s then
        local args = {
            "--build", ".",
            "--config", s.config.mode,
            "-j" .. Utils.get_number_of_cores(),
        }

        self.project:execute_async("cmake", args, {
            title = "CMake - Build",
            state = "build",
        })
    end
end

function CMake:run()
    local s = self:check_settings()

    if s then
        local filepath = self:get_executable_filepath(s.runconfig)

        if filepath then
            self:do_run(filepath, s.runconfig.cmdline, {build = true})
        else
            Utils.notify("Cannot run configuration '" .. s.runconfig.name .. "'")
        end
    end
end

function CMake:debug(options)
    local s = self:check_settings()

    if s then
        self.project:run_dap({
            request = "launch",
            type = "codelldb",
            program = tostring(self:get_executable_filepath(s.runconfig)),
            args = s.runconfig.arguments and vim.split(s.runconfig.arguments, " ") or nil,
        }, options or { })
    else
        Utils.notify("Cannot debug configuration '" .. s.runconfig.name .. "'")
    end
end

function CMake:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        local buildheader = {
            {
                name = "mode", label = "Mode", type = Cells.SelectCell,
                items = function() return self:get_modes() end
            },
        }

        local runheader = {
            {
                name = "target", label = "Target", type = Cells.SelectCell,
                items = function() return self:get_targets() end
            },
        }

        dlg(self, {
            buildheader = buildheader,
            runheader = runheader,
            showcommand = false
        }):popup(function()
            self:configure()
        end)
    end
end

return CMake
