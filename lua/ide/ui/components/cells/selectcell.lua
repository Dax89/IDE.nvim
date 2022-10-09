local Utils = require("ide.utils")
local Cell = require("ide.ui.components.cells.cell")

local SelectCell = Utils.class(Cell)

function SelectCell:create()
    self.options.items = self.header.items
    self.options.changed = function(_, v) self:update(v) end
    local Select = require("ide.ui.components.select")
    return Select(self.label, vim.F.if_nil(self.value, ""), self.options)
end

return SelectCell


