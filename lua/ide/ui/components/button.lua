local Utils = require("ide.utils")
local Label = require("ide.ui.components.label")

local private = Utils.private_stash()
local Button = Utils.class(Label)

function Button:init(text, options)
    options = options or { }
    self.background = vim.F.if_nil(options.background, "primary")
    self.foreground = vim.F.if_nil(options.foreground, "primary")

    private[self] = {
        event = options.event
    }

    Label.init(self, " " .. text .. " ", options)
end

function Button:on_event(e)
    if vim.is_callable(private[self].event) then
        private[self].event({sender = self, event = e})
    end
end

return Button
