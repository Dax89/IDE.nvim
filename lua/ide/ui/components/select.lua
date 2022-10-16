local Utils = require("ide.utils")
local Input = require("ide.ui.components.input")

local private = Utils.private_stash()
local Select = Utils.class(Input)

function Select:init(label, value, options)
    options = options or { }
    options.icon = vim.F.if_nil(options.icon, "")

    private[self] = {
        empty = vim.F.if_nil(options.empty, false),
        items = vim.F.if_nil(options.items, { }),
        changed = options.changed,
        formatitem = options.formatitem,
    }

    Input.init(self, label, value, options)
end

function Select:_default_format_item(item)
    if self:get_value() and (item == self:get_value() or item.value == self:get_value()) then
        return (item.text or item) .. " - SELECTED"
    end

    return item and item.text or item
end

function Select:_get_items()
    local items = {}

    if private[self].items then
        if vim.is_callable(private[self].items) then
            items = private[self].items(self)
        elseif type(private[self].items) == "table" then
            items = private[self].items
        end
    end

    return items
end

function Select:get_display_value()
    local items = self:_get_items()

    if not vim.tbl_isempty(items) then
        for _, item in ipairs(items) do
            if item == self:get_value() or item.value == self:get_value() then
                return item.text or item.value or item
            end
        end
    end

    return Input.get_display_value(self)
end

function Select:_find_selected(items)
    if self:get_value() then
        for i, item in ipairs(items) do
            if (item.value or item) == self:get_value() then
                return i
            end
        end
    end

    return 0
end

function Select:on_event(e)
    local items = self:_get_items()

    if vim.tbl_isempty(items) then
        return
    end

    local idx = self:_find_selected(items) -- Make selected item first

    if idx ~= 0 then
        table.insert(items, 1, table.remove(items, idx))
    end

    if private[self].empty then
        table.insert(items, 1, "")
    end

    vim.ui.select(items, {
        prompt = self.label,
        format_item = function(item)
            if vim.is_callable(private[self].formatitem) then
                return private[self].formatitem(self, item)
            end
            return self:_default_format_item(item)
        end
    }, function(choice)
        if choice then
            local oldvalue = self:get_value()
            self:set_value(choice.value or choice)

            if vim.is_callable(private[self].changed) then
                private[self].changed(self, choice.value or choice, oldvalue)
            end

            e.update()
        end
    end)
end

return Select
