local Utils = require("ide.utils")
local Cell = require("ide.ui.components.cells.cell")

local LabelCell = Utils.class(Cell)

function LabelCell:create()
    local Label = require("ide.ui.components.label")
    return Label(vim.F.if_nil(self.value, ""), self.options)
end

return LabelCell
