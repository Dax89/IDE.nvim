local Utils = require("ide.utils")

local Cell = Utils.class()

function Cell:init(celldata)
    -- Copy 'celldata' in 'self'
    for k, v in pairs(celldata) do
        self[k] = v
    end
end

function Cell:update(v)
    self.do_update(v)
end

function Cell:create()
    return nil
end

return Cell
