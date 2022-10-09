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

function CMake:on_ready()
    for _, m in ipairs(CMake.BUILD_MODES) do
        self.project:check_config(m, {
            mode = m,
            cwd = self.project:get_build_path(true, m),
        })
    end

    if not self.project:get_selected_config() then
        self.project:set_selected_config(CMake.BUILD_MODES[1])
    end

    self.project:write()
end

function CMake:_write_query(q)
    local p = Path:new(self.project:get_build_path(), ".cmake", "api", CMake.API_VERSION, "query")
    p:mkdir({parents = true, exists_ok = true})
    local qobj = Path:new(p, q)
    qobj:touch()
end

function CMake:_read_query(q)
    local p = Path:new(self.project:get_build_path(), ".cmake", "api", CMake.API_VERSION, "reply")

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

function CMake:get_targets()
    local codemodel = self:_read_query("codemodel-v2")

    if codemodel and codemodel.configurations and not vim.tbl_isempty(codemodel.configurations) then
        return vim.tbl_map(function(t)
            return t.name
        end, codemodel.configurations[1].targets)
    end

    return {}
end

function CMake:_configure(options)
    options = options or { }
    self:_write_query("codemodel-v2")

    local selcfg = self.project:get_selected_config()

    self.project:new_job("cmake", {
        "-B", self.project:get_build_path(true),
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_BUILD_TYPE=" .. selcfg.mode
    }, vim.tbl_extend("keep", {title = "CMake - Configure", src = true, state = "configure"}, options))

    local compilecommands = Path:new(self.project:get_build_path(), "compile_commands.json")

    if compilecommands:is_file() then
        compilecommands:copy({destination = Path:new(self.project:get_path(), "compile_commands.json" )})
    end
end

function CMake:configure()
    Builder.configure(self)
    self:_configure()
end

function CMake:build(_, onexit)
    self:check_settings(function(_, config)
        local args = {
            "--build", ".",
            "--config", config.mode,
            "-j" .. Utils.get_number_of_cores(),
        }

        self.project:new_job("cmake", args, {title = "CMake - Build", state = "build", onexit = onexit})
    end)
end

function CMake:run()
    self:check_settings(function(_, config)
        local targetdata = self:_read_query("target-" .. config.target)

        if targetdata then
            if targetdata.type == "EXECUTABLE" then
                self:check_and_run(Path:new(self.project:get_build_path(true), targetdata.artifacts[1].path), config.cmdline, config)
            else
                Utils.notify("Cannot run target of type '" .. targetdata.type .. "'")
            end
        end
    end)
end

function CMake:debug(options)
    self:check_settings(function(_, config)
        self.project:run_dap({
            request = "launch",
            type = "codelldb",
            program = tostring(Path:new(self.project:get_build_path(true), config.target)),
            args = config.cmdline,
        }, options or { })
    end)
end

function CMake:settings()
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

return CMake
