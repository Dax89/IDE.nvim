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
        changed = options.changed,
        removed = options.removed,
        added = options.added,
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
        added = function(_, d, pos)
            if vim.is_callable(private[self].added) then
                private[self].added(self, d, pos)
            end
        end,

        removed = function(_, d, idx)
            if vim.is_callable(private[self].removed) then
                private[self].removed(self, d, idx)
            end
        end,

        changed = function(_, d)
            if vim.is_callable(private[self].changed) then
                private[self].changed(self, d)
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

