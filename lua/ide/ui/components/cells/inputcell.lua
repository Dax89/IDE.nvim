local Utils = require("ide.utils")
local Cell = require("ide.ui.components.cells.cell")

local InputCell = Utils.class(Cell)

function InputCell:create()
    self.options.change = function(_, v) self:update(v) end
    local Input = require("ide.ui.components.input")
    return Input(self.label, vim.F.if_nil(self.value, ""), self.options)
end

return InputCell

