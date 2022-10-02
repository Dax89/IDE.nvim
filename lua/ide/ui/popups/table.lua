local Utils = require("ide.utils")
local Dialog = require("ide.ui.dialogs.dialog")

local TableDialog = Utils.class(Dialog)

function TableDialog:init(items, title, options)
    self.items = items or { }
    Dialog.init(self, title, options)
end

return Dialog
