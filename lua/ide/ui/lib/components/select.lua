local Utils = require("ide.utils")
local Input = require("ide.ui.lib.components.input")

local Select = Utils.class(Input)

function Select:init(label, value, options)
    options = options or { }
    options.icon = options.icon or ""
    Input.init(self, label, value, options)

    self._items = options.items or {}
    self._format_item = options.format_item
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

    vim.ui.select(items, {
        prompt = self._label,
        format_item = self._format_item
    }, function(choice)
        self._value = choice.value or choice
        e.update()
    end)
end

return Select
