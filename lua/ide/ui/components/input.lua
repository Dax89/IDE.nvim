local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local private = Utils.private_stash()
local Input = Utils.class(Base.Component)

function Input:init(label, value, options)
    options = options or { }

    self.label = vim.F.if_nil(label, "")

    private[self] = {
        showlabel = vim.F.if_nil(options.showlabel, true),
        showicon = vim.F.if_nil(options.showicon, true),
        align = vim.F.if_nil(options.align, "left"),
        value = vim.F.if_nil(value, ""),
        format = vim.F.if_nil(options.format, "%s"),
        icon = #self.label > 0 and vim.F.if_nil(options.icon, "") or nil,
        change = options.change
    }

    Base.Component.init(self, options)
end

function Input:set_value(v)
    private[self].value = vim.F.if_nil(v, "")
end

function Input:get_value()
    return private[self].value
end

function Input:render(buffer)
    local s = ""

    if private[self].showicon and private[self].icon then
        s = private[self].icon .. " "
    end

    if private[self].showlabel then
        s = s .. self.label
    end

    if private[self].align == "left" then
        return s .. " "  .. string.format(private[self].format, private[self].value), buffer
    end

    -- FIXME: self.label is not counted in alignment
    return s .. self:_aligned_text(string.format(private[self].format, private[self].value), buffer)
end

function Input:on_click(_)
end

function Input:on_doubleclick(e)
    self:on_event(e)
end

function Input:on_event(e)
    vim.ui.input({prompt = self.label}, function(choice)
        if choice then
            local oldvalue = private[self].value
            private[self].value = choice

            if vim.is_callable(private[self].change) then
                private[self].change(self, choice, oldvalue)
            end

            e.update()
        end
    end)
end

return Input
