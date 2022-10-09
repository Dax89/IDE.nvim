local Utils = require("ide.utils")
local Dialogs = require("ide.internal.dialogs")

local CMakeSettings = Utils.class(Dialogs.ConfigDialog)

function CMakeSettings:init(builder, header)
    builder:configure()

    Dialogs.ConfigDialog.init(self, builder, header, {
        actions = {"Configure"},

        actionselected = function(_, idx)
            if idx == 1 then
                builder:configure()
            end
        end
    })

    vim.api.nvim_command("wincmd p")
end

return CMakeSettings
