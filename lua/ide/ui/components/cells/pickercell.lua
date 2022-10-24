local Utils = require("ide.utils")
local Cell = require("ide.ui.components.cells.cell")

local PickerCell = Utils.class(Cell)

function PickerCell:create()
    self.options.change = function(_, v) print(v) self:update(tostring(v)) end
    local Picker = require("ide.ui.components.picker")
    return Picker(self.label, vim.F.if_nil(self.value, ""), self.options)
end

return PickerCell


