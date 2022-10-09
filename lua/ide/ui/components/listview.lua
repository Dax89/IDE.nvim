local Utils = require("ide.utils")
local Button = require("ide.ui.components.button")

local private = Utils.private_stash()
local ListView = Utils.class(Button)

function ListView:init(text, options)
    options = options or { }

    self.items = vim.F.if_nil(options.items, { })

    private[self] = {
        popupoptions = {
            editable = options.editable,
            unique = options.unique,
            width = options.view and options.view.width or nil,
            height = options.view and options.height or nil,
        },

        selected = options.selected,
        changed = options.changed,
        removed = options.removed,
        added = options.added,
    }

    Button.init(self, text, options)
end

function ListView:on_event(_)
    local items = { }

    if vim.is_callable(self.items) then
        items = self.items(self)
    elseif vim.tbl_islist(self.items) then
        items = self.items
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


    local pplist = require("ide.ui.popups.list")(items, self.text, ppoptions)
    pplist:show()
end

return ListView
