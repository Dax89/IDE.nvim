local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local private = Utils.private_stash()
local CheckBox = Utils.class(Base.Component)

function CheckBox:init(label, checked, options)
    options = options or { }

    self.label = vim.F.if_nil(label, "")
    self.align = vim.F.if_nil(options.align, "left")

    private[self] = {
        showlabel = vim.F.if_nil(options.showlabel, true),
        flat = vim.F.if_nil(options.flat, false),
        checked = checked == true,
        changed = options.changed,
    }

    Base.Component.init(self, options)
end

function CheckBox:set_value(v)
    local value, oldvalue = vim.F.if_nil(v, false), private[self].value

    if value ~= oldvalue then
        private[self].checked = value

        if vim.is_callable(private[self].changed) then
            private[self].changed(self, value, oldvalue)
        end
    end
end

function CheckBox:get_value()
    return private[self].checked
end

function CheckBox:render(buffer)
    local s = ""

    if private[self].flat then
        s = private[self].checked == true and "" or ""
    else
        s = private[self].checked == true and "" or ""
    end

    if private[self].showlabel and #self.label > 0 then
        s = s .. " " .. self.label
    end

    return self:_aligned_text(s, buffer)
end

function CheckBox:on_event(e)
    self:set_value(not private[self].checked)
    e.update()
end

return CheckBox
