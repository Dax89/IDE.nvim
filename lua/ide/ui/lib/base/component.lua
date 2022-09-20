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
