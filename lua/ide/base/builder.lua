local Utils = require("ide.utils")

local Builder = Utils.class()

function Builder:init(project)
    self.project = project
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

function Builder:stop()
end

function Builder:settings()
end

function Builder:on_ready()
end

return Builder
