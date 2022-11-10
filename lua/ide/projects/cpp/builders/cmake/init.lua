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
    self:_configure({
        onexit = function()
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
    }, CMake.BUILD_MODES[1])
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

function CMake:_configure(options, mode)
    options = options or { }
    self:_write_query("codemodel-v2", mode)

    if not mode then
        mode = self.project:get_selected_config().mode
    end

    self.project:new_job("cmake", {
        "-B", self.project:get_build_path(true, mode),
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_BUILD_TYPE=" .. mode,
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

        self.project:new_job("cmake", args, {
            title = "CMake - Build",
            state = "build",
            onexit = onexit
        })
    end)
end

function CMake:run()
    self:check_settings(function(_, _, runconfig)
        local targetdata = self:_read_query("target-" .. runconfig.target)

        if targetdata then
            self:check_and_run(Path:new(self.project:get_build_path(true), targetdata.artifacts[1].path), runconfig.cmdline, runconfig)
        else
            Utils.notify("Cannot run configuration'" .. runconfig.name .. "'")
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
