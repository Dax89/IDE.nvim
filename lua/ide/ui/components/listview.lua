local Utils = require("ide.utils")
local Button = require("ide.ui.components.button")

local private = Utils.private_stash()
local ListView = Utils.class(Button)

function ListView:init(text, options)
    options = options or { }

    private[self] = {
        items = vim.F.if_nil(options.items, { }),

        popupoptions = {
            unique = options.unique,
            width = options.view and options.view.width or nil,
            height = options.view and options.height or nil,
            selected = options.selected,
            add = options.add,
            remove = options.remove,
        }
    }

    Button.init(self, text, options)
end

function ListView:on_event(_)
    local items = { }

    if vim.is_callable(private[self].items) then
        items = private[self].items(self)
    elseif vim.tbl_islist(private[self].items) then
        items = private[self].items
    end

    local pplist = require("ide.ui.popups.list")(items, self.text, private[self].popupoptions)
    pplist:show()
end

return ListView
