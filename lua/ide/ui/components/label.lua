local Utils = require("ide.utils")
local Base = require("ide.ui.base")

local private = Utils.private_stash()
local Label = Utils.class(Base.Component)

function Label:init(text, options)
    options = options or { }

    self.text = vim.F.if_nil(text, "")

    private[self] = {
        autosize = options.autosize or (options.width == nil)
    }

    if private[self].autosize then
        local UTF8 = require("ide.ui.utils.utf8")
        self.width = UTF8.len(self.text)
    end

    Base.Component.init(self, options)
end

function Label:render(canvas)
    return self:_aligned_text(self.text, canvas)
end

return Label
