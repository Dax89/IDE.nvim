local Utils = require("ide.utils")
local Cell = require("ide.ui.components.cells.cell")

local CheckCell = Utils.class(Cell)

function CheckCell:create()
    self.options.change = function(_, v) self:update(v) end
    local CheckBox = require("ide.ui.components.checkbox")
    return CheckBox(self.label, vim.F.if_nil(self.value, false), self.options)
end

return CheckCell
