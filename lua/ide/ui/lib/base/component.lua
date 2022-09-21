local Utils = require("ide.utils")

local Component = Utils.class()

function Component:init(options)
    options = options or { }

    self.id = options.id
    self.key = options.key
    self.row = options.row or 0
    self.col = options.col or 0
    self.width = options.width or 1
    self.height = options.height or 1
    self.bold = options.bold or false
    self.background = options.background
    self.foreground = options.foreground
end

function Component:_aligned_text(text, canvas)
    local len, w = #text, canvas:calc_width(self)
    local pad, s = string.rep(" ", math.max(math.ceil((w - len)), 0)), ""

    if self._align == "center" then
        s = pad:sub(0, #pad / 2) .. text .. pad:sub(0, #pad / 2)
    elseif self._align == "right" then
        s = pad .. text
    else
        s = text .. pad
    end

    return s
end

function Component:set_value(v)
end

function Component:get_value()
    return nil
end

function Component:render()
    error("Component:render() is abstract")
end

function Component:on_click(e)
    self:on_event(e)
end

function Component:on_doubleclick(e)
end

function Component:on_event(e)
end

return Component
