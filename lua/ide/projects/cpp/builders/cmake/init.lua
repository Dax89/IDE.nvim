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

function CMake:_select_mode(cb)
    local currmode = self.project:get_mode()

    vim.ui.select(CMake.BUILD_MODES, {
        prompt = "Select Mode",
        format_item = function(mode)
            return currmode == mode and mode .. " - SELECTED" or mode
        end
    }, function(mode)
        if mode then
            self.project:set_mode(mode)
            self.project:write()
            self:_configure({sync = true})
            vim.F.npcall(cb, mode)
        end
    end)
end

function CMake:_select_target(cb)
    local targets = self:get_targets()
    local currtarget = self.project:get_option("target")

    vim.ui.select(targets, {
        prompt = "Select Target",
        format_item = function(target)
            return currtarget == target and target .. " - SELECTED" or target
        end
    }, function(target)
        if target then
            self.project:set_option("target", target)
            self.project:write()
            vim.F.npcall(cb, target)
        end
    end)
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

    if not self.project:get_option("target") then
        local targets = self:get_targets()
        if not vim.tbl_isempty(targets) then
            self.project:set_option("target", targets[1])
            self.project:write()
        end
    end
end

function CMake:configure()
    Builder.configure(self)
    self:_configure()
end

function CMake:build(target)
    local args = {
        "--build", ".",
        "--config", self.project:get_mode(),
        "-j" .. Utils.get_number_of_cores()
    }

    if type(target) == "string" then
        args = vim.tbl_extend(args, {"--target", target})
    end

    self.project:new_job("cmake", args, {title = "CMake - Build", state = "build"})
end

function CMake:run()
    local mode = self.project:get_mode()

    if not mode then
        self:_select_mode(function()
            self:run()
        end)

        return
    end

    local target = self.project:get_option("target")

    if target then
        local targetdata = self:_read_query("target-" .. target)

        if not targetdata then
            return
        end

        if targetdata.type ~= "EXECUTABLE" then
            error("Cannot run target of type '" .. targetdata.type .. "'")
        end

        local p = Path:new(self.project:get_build_path(true), targetdata.artifacts[1].path)

        if p:is_file() then
            self.project:new_job(p, nil, {title = "Run - " .. target, state = "run"})
        else
            error("Cannot execute '" .. tostring(p) .. "', file not found")
        end

        return
    end

    self:_select_target(function()
        self:run()
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
