local Utils = require("ide.utils")
local Path = require("plenary.path")
local Builder = require("ide.base.builder")

local CMake = Utils.class(Builder)
CMake.BUILD_MODES = {"Debug", "Release", "RelWithDebInfo", "MinSizeRel"}
CMake.API_VERSION = "v1"

function CMake:get_type()
    return "cmake"
end

function CMake:on_ready()
    if not self.project:get_mode() then
        self.project:set_mode(CMake.BUILD_MODES[1])
    end
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

    return { }
end

function CMake:_configure(options)
    options = options or { }
    self:_write_query("codemodel-v2")

    self.project:new_job("cmake", {
        "-B", self.project:get_build_path(true),
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=1",
        "-DCMAKE_BUILD_TYPE=" .. self.project:get_mode()
    }, vim.tbl_extend("keep", {title = "CMake - Configure", src = true, state = "configure"}, options))

    local compilecommands = Path:new(self.project:get_build_path(), "compile_commands.json")

    if compilecommands:is_file() then
        compilecommands:copy({destination = Path:new(self.project:get_path(), "compile_commands.json" )})
    end

    if not self.project:get_target() then
        local targets = self:get_targets()
        if not vim.tbl_isempty(targets) then
            self.project:set_target(targets[1])
            self.project:write()
        end
    end
end

function CMake:configure()
    Builder.configure(self)
    self:_configure()
end

function CMake:build(target, onexit)
    local args = {
        "--build", ".",
        "--config", self.project:get_mode(),
        "-j" .. Utils.get_number_of_cores()
    }

    if type(target) == "string" then
        args = vim.tbl_extend(args, {"--target", target})
    end

    self.project:new_job("cmake", args, {title = "CMake - Build", state = "build", onexit = onexit})
end

function CMake:run()
    self:check_settings(function(_, _, target)
        local targetdata = self:_read_query("target-" .. target)

        if targetdata then
            if targetdata.type ~= "EXECUTABLE" then
                error("Cannot run target of type '" .. targetdata.type .. "'")
            end

            self:check_and_run(Path:new(self.project:get_build_path(true), targetdata.artifacts[1].path), target)
        end
    end)
end

function CMake:debug(options)
    options = options or { }

    self.project:run_dap({
        request = "launch",
        type = "codelldb",
        program = tostring(Path:new(self.project:get_build_path(true), self.project:get_option("target"))),
    }, options)
end

return CMake
