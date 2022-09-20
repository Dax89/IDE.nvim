local Utils = require("ide.utils")
local Base = require("ide.ui.lib.base")

local Label = Utils.class(Base.Component)

function Label:init(text, options)
    self._text = text or ""

    options = options or { }
    options.width = #self._text

    Base.Component.init(self, options)
end

function Label:get_text()
    return self._text
end

function Label:set_text(t)
    self._text = t or ""
    self.width = #self._text
end

function Label:render(_)
    return self._text
end

return Label
