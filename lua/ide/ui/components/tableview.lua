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
        change = options.change,
        remove = options.remove,
        add = options.add,
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

    local ppoptions = vim.tbl_extend("force", private[self].popupoptions, {
        add = function(_, d, pos)
            if vim.is_callable(private[self].add) then
                private[self].add(self, d, pos)
            end
        end,

        remove = function(_, d, idx)
            if vim.is_callable(private[self].remove) then
                private[self].remove(self, d, idx)
            end
        end,

        change = function(_, d)
            if vim.is_callable(private[self].change) then
                private[self].change(self, d)
            end
        end,

        selected = function(_, row, col)
            if vim.is_callable(private[self].selected) then
                private[self].selected(self, row, col)
            end
        end
    })

    local ppheader = require("ide.ui.popups.table")(header, data, self.text, ppoptions)
    ppheader:popup()
end

return TableView

