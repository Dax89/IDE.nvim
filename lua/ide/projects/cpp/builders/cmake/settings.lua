local Utils = require("ide.utils")
local Dialogs = require("ide.internal.dialogs")
local Components = require("ide.ui.lib.components")

local CMakeSettings = Utils.class(Dialogs.BuilderDialog)

function CMakeSettings:init(builder)
    Dialogs.BuilderDialog.init(self, builder)
    builder:configure()
    vim.api.nvim_command("wincmd p")

    self:set_components({
        {},
        {
            Components.Button("Run Configure", {
                col = 0,
                event = function()
                    self.builder:configure()
                end
            }),
            Components.Button("Save", {
                col = -1,
                event = function()
                    self:accept()
                end
            })
        }
    })
end

return CMakeSettings
