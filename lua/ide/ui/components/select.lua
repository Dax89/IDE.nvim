local Utils = require("ide.utils")
local Input = require("ide.ui.components.input")

local Select = Utils.class(Input)

function Select:init(label, value, options)
    options = options or { }
    options.icon = options.icon or ""
    Input.init(self, label, value, options)

    self._empty = options.empty or false
    self._items = options.items or {}
    self._change = options.change
    self._formatitem = options.formatitem
end

function Select:_default_format_item(item)
    if self._value and item == self._value then
        return (item.text or item) .. " - SELECTED"
    end

    return item and item.text or item
end

function Select:_find_selected(items)
    if self._value then
        for i, item in ipairs(items) do
            if (item.value or item) == self._value then
                return i
            end
        end
    end

    return 0
end

function Select:on_event(e)
    local items = {}

    if self._items then
        if vim.is_callable(self._items) then
            items = self._items(self)
        elseif type(self._items) == "table" then
            items = self._items
        end
    end

    if vim.tbl_isempty(items) then
        return
    end

    local idx = self:_find_selected(items) -- Make selected item first

    if idx ~= 0 then
        table.insert(items, 1, table.remove(items, idx))
    end

    if self._empty then
        table.insert(items, 1, "")
    end

    vim.ui.select(items, {
        prompt = self._label,
        format_item = function(item)
            if vim.is_callable(self._formatitem) then
                return self._format_item(self, item)
            end
            return self:_default_format_item(item)
        end
    }, function(choice)
        if choice then
            local oldvalue = self._value
            self:set_value(choice.value or choice)
            vim.F.npcall(self._change, self, choice.value or choice, oldvalue)
            e.update()
        end
    end)
end

return Select
