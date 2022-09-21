local Utils = require("ide.utils")
local Builder = require("ide.base.builder")

local Cargo = Utils.class(Builder)

function Cargo:get_type()
    return "cargo"
end

function Cargo:create()
    self.project:execute("cargo", {"init", "--name", self.project:get_name(), self.project:get_path(true)}, {src = true})
end

function Cargo:stop()
    if self._runjob then
        self._runjob:shutdown()
        self._runjob = nil
    end
end

function Cargo:build()
    local b = self.project:get_build_path()

    local args = {
        "build",
        "--target-dir", tostring(b)
    }

    b:mkdir({parents = true, exists_ok = true})

    self._runjob = self.project:new_job("cargo", args, {
        title = "Cargo - Build",
        state = "build"
    })
end

return Cargo

