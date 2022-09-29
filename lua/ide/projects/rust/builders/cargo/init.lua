local Utils = require("ide.utils")
local Builder = require("ide.base.builder")

local Cargo = Utils.class(Builder)
Cargo.BUILD_MODES = {"debug", "release"}

function Cargo:_get_manifest()
    return self.project:execute("cargo", {"read-manifest"}, {json = true, src = true})
end

function Cargo:get_type()
    return "cargo"
end

function Cargo:get_modes()
    return Cargo.BUILD_MODES
end

function Cargo:create()
    local _, code = self.project:execute("cargo", {"init", "--name", self.project:get_name(), self.project:get_path(true)}, {src = true})

    if code ~= 0 then
        Utils.notify("Cargo: Project creation failed", "error", {title = "ERROR"})
    end
end

function Cargo:get_targets()
    local m = self:_get_manifest()

    return vim.tbl_map(function(t)
        return t.name
    end, m.targets)
end

function Cargo:build()
    local b = self.project:get_build_path()

    local args = {
        "build",
        "--target-dir", tostring(b:parent())
    }

    local m = self.project:get_mode()

    if m and m ~= "debug" then -- Cargo says that 'debug' is a reserved name
        args = vim.list_extend(args, {"--profile", self.project:get_mode()})
    end

    b:mkdir({parents = true, exists_ok = true})

    self.project:new_job("cargo", args, {
        title = "Cargo - Build",
        state = "build"
    })
end

function Cargo:debug(options)
    local Path = require("plenary.path")
    options = options or { }

    self.project:run_dap({
        request = "launch",
        type = "codelldb",
        program = tostring(Path:new(self.project:get_build_path(true), self.project:get_option("target"))),
    }, options)
end

function Builder:settings()
    local d = require("ide.internal.dialogs")

    d.BuilderDialog(self, {save = true}):popup(function()
        self.project:write()
    end)
end

return Cargo

