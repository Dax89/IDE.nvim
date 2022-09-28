local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local Label = Utils.class(Base.Component)

function Label:init(text, options)
    options = options or { }

    self._text = text or ""
    self._autosize = options.autosize or (options.width == nil)
    self._align = options.align or "left"

    if self._autosize then
        options.width = #self._text
    end

    Base.Component.init(self, options)
end

function Label:render(canvas)
    return self:_aligned_text(self._text, canvas)
end

return Label
