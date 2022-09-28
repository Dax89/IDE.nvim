local Utils = require("ide.utils")
local Label = require("ide.ui.components.label")

local Button = Utils.class(Label)

function Button:init(text, options)
    options = options or { }
    options.background = options.background or "CurSearch"
    options.foreground = options.foreground or "CurSearch"
    self._event = options.event
    Label.init(self, " " .. text .. " ", options)
end

function Button:on_event(e)
    vim.F.npcall(self._event, {sender = self, event = e})
end

return Button
