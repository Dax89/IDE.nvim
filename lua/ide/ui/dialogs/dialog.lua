local Utils = require("ide.utils")
local Popup = require("ide.ui.base.popup")

local Dialog = Utils.class(Popup)

function Dialog:init(title, options)
    self._title = title
    Popup.init(self, options)
end

function Dialog:set_components(components)
    local hidx, c, Components = 1, components, require("ide.ui.components")

    if self._title then
        c = vim.list_extend({
            Components.Label(self._title, {width = "100%", align = "center", foreground = "Title"}),
            Components.HLine(),
        }, components)

        hidx = 2
    end

    if self.options.showhelp ~= false then
        table.insert(c, hidx, {
            Components.Label("Press '<C-h>' for Help", {width = "100%", align = "center", foreground = "Comment"})
        })
    end

    Popup.set_components(self, c)
end

function Dialog:accept()
    if not self:validate_model() then
        return
    end

    self:on_accept(self.model)

    if vim.is_callable(self._onaccept) then
        if self._onaccept(self.model, self) ~= false then
            self:close()
        end
    else
        self:close()
    end
end

function Dialog:popup(cb)
    if not self.hwin then
        self._onaccept = cb
    end

    self:show()
end

function Dialog:on_accept(model)
end

function Dialog:on_escape()
    self:close()
end

return Dialog
