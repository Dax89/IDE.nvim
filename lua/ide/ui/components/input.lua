local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local private = Utils.private_stash()
local Input = Utils.class(Base.Component)

function Input:init(label, value, options)
    options = options or { }

    self.label = vim.F.if_nil(label, "")

    private[self] = {
        value = vim.F.if_nil(value, ""),
        format = vim.F.if_nil(options.format, "%s"),
        icon = vim.F.if_nil(options.icon, ""),
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

function Input:render(_)
    local s = ""

    if private[self].icon then
        s = private[self].icon .. " "
    end

    return s .. self.label .. " "  .. string.format(private[self].format, private[self].value)
end

function Input:on_click(_)
end

function Input:on_doubleclick(e)
    self:on_event(e)
end

function Input:on_event(e)
    vim.ui.input(self.label, function(choice)
        local oldvalue = private[self].value
        private[self].value = choice
        vim.F.npcall(private[self].change, self, choice, oldvalue)
        e.update()
    end)
end

return Input
