local Utils = require("ide.utils")
local Button = require("ide.ui.components.button")

local ListView = Utils.class(Button)

function ListView:init(text, options)
    options = options or { }
    Button.init(self, text, options)

    self._items = options.items

    self._popupoptions = {
        unique = options.unique,
        width = options.width,
        height = options.height,
        selected = options.selected,
        add = options.add,
        remove = options.remove,
    }
end

function ListView:on_event(_)
    local items = { }

    if vim.tbl_islist(self._items) then
        items = self.options.items
    elseif vim.is_callable(self._items) then
        items = self._items(self)
    end

    local pplist = require("ide.ui.popups.list")(items, self._text, self._popupoptions)
    pplist:show()
end

return ListView
