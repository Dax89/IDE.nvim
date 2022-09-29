local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local Input = Utils.class(Base.Component)

function Input:init(label, value, options)
    options = options or { }

    self._label = label or ""
    self._value = value or ""
    self._format = options.format or "%s"
    self._icon = options.icon or ""
    self._change = options.change
    self:_update_width()

    Base.Component.init(self, options)
end

function Input:_update_width()
    local w, UTF8 = 0, require("ide.ui.utils.utf8")

    if self._icon then
        w = UTF8.len(self._icon)
    end

    if self._label then
        w = w + UTF8.len(self._label)
    end

    if self._value then
        w = w + UTF8.len(string.format(self._format, self._value))
    end

    self.width = w
end

function Input:set_value(v)
    self._value = v or ""
end

function Input:get_value()
    return self._value
end

function Input:render(_)
    local s = ""

    if self._icon then
        s = self._icon .. " "
    end

    return s .. self._label .. " "  .. string.format(self._format, self._value)
end

function Input:on_click(_)
end

function Input:on_doubleclick(e)
    self:on_event(e)
end

function Input:on_event(e)
    vim.ui.input(self._label, function(choice)
        local oldvalue = self._value
        self._value = choice
        vim.F.npcall(self._change, self, choice, oldvalue)
        e.update()
    end)
end

return Input
