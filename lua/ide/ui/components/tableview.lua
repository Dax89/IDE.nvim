local Utils = require("ide.utils")
local Button = require("ide.ui.components.button")

local private = Utils.private_stash()
local TableView = Utils.class(Button)

function TableView:init(text, options)
    options = options or { }
    Button.init(self, text, options)

    self.header = options.header or { }
    self.data = options.data or { }

    private[self] = {
        popupoptions = {
            width = options.view and options.view.width or nil,
            height = options.view and options.view.height or nil,
        },

        selected = options.selected,
        add = options.add,
        remove = options.remove,
    }
end

function TableView:on_event(_)
    local header, data = { }, { }

    if vim.tbl_islist(self.header) then
        header = self.header
    elseif vim.is_callable(self.header) then
        header = self.header(self)
    end

    if vim.tbl_islist(self.data) then
        data = self.data
    elseif vim.is_callable(self.data) then
        data = self.data(self)
    end

    local ppheader = require("ide.ui.popups.table")(header, data, self.text, private[self].popupoptions)
    ppheader:show()
end

return TableView

