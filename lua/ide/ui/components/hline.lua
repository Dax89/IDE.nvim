local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local HLine = Utils.class(Base.Component)

function HLine:init(options)
    options = options or { }
    self.width = options.width or "100%" -- FIXME: if 50% is wrong
    Base.Component.init(self, options)
end

function HLine:render(canvas)
    local UTF8 = require("ide.ui.utils.utf8")
    return UTF8.rep("⎯", canvas:calc_width(self))
end

return HLine
