local Utils = require("ide.utils")
local Label = require("ide.ui.components.label")

local private = Utils.private_stash()
local Button = Utils.class(Label)

function Button:init(text, options)
    options = options or { }

    self.flat = vim.F.if_nil(options.flat, false)
    self.align = vim.F.if_nil(options.align, "center")

    if type(options.background) == "string" then
        self.background = options.background
    elseif self.flat then
        self.background = nil
    else
        self.background = "primary"
    end

    if type(options.foreground) == "string" then
        self.foreground = options.foreground
    elseif self.flat then
        self.foreground = nil
    else
        self.foreground = "primary"
    end

    private[self] = {
        click = options.click
    }

    Label.init(self, " " .. text .. " ", options)
end

function Button:on_event(e)
    if vim.is_callable(private[self].click) then
        private[self].click({sender = self, event = e})
    end
end

return Button
