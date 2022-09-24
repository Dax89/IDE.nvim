local Utils = require("ide.utils")

local Builder = Utils.class()

function Builder:init(project)
    self.project = project
end

function Builder:get_type()
    error("Builder:get_type() is abstract")
end

function Builder:rebuild()
    self.project:get_build_path():rmdir()
    self:build()
end

function Builder:configure()
    self.project:get_build_path():mkdir()
end

function Builder:build()
    self.project:get_build_path():mkdir()
end

function Builder:debug(_)
    self.project:get_build_path():mkdir()
end

function Builder:create()
end

function Builder:settings()
    local ok, d = pcall(require, "ide.projects." .. self.project:get_type() ..
                                 ".builders." .. self:get_type() ..
                                 ".settings")

    if ok then
        d(self):show()
    end
end

function Builder:on_ready()
end

return Builder
