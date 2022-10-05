local Utils = require("ide.utils")

local Component = Utils.class()

function Component:init(options)
    options = options or { }

    self.id = vim.F.if_nil(self.id, options.id)
    self.key = vim.F.if_nil(self.key, options.key)
    self.background = vim.F.if_nil(self.background, options.background)
    self.foreground = vim.F.if_nil(self.foreground, options.foreground)
    self.row = vim.F.if_nil(self.row, vim.F.if_nil(options.row, 0))
    self.col = vim.F.if_nil(self.col, vim.F.if_nil(options.col, 0))
    self.width = vim.F.if_nil(self.width, vim.F.if_nil(options.width, 1))
    self.height = vim.F.if_nil(self.height, vim.F.if_nil(options.height, 1))
    self.bold = vim.F.if_nil(self.bold, vim.F.if_nil(options.bold, false))
    self.optional = vim.F.if_nil(self.optional, vim.F.if_nil(options.optional, false))
    self.align = vim.F.if_nil(self.align, vim.F.if_nil(options.align, "left"))
end

function Component:_aligned_text(text, canvas)
    local UTF8 = require("ide.ui.utils.utf8")
    local len, w = UTF8.len(text), canvas:calc_width(self)
    local pad, s = string.rep(" ", math.max(math.ceil((w - len)), 0)), ""

    if self.align == "center" then
        s = pad:sub(0, UTF8.len(pad) / 2) .. text .. pad:sub(0, #pad / 2)
    elseif self.align == "right" then
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
