local Utils = require("ide.utils")
local Dialogs = require("ide.internal.dialogs")

local CargoSettings = Utils.class(Dialogs.ConfigDialog)

function CargoSettings:init(builder, header)
    builder:configure()

    Dialogs.ConfigDialog.init(self, builder, header, {
        actions = {"Assign Target"},

        actionselected = function(_, idx)
            if idx == 1 then
                vim.ui.select(builder:get_targets(), {
                    prompt = "Targets"
                },
                function(target)
                    if target then
                        self:assign_target(target)
                    end
                end)
            end
        end
    })

    vim.api.nvim_command("wincmd p")
end

function CargoSettings:assign_target(target)
    for _, d in ipairs(self:get_data()) do
        d.target = target
    end

    self:update() -- NOTE: Find a better implementation
end

return CargoSettings

