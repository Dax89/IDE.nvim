local Utils = require("ide.utils")
local Dialogs = require("ide.internal.dialogs")

local CMakeSettings = Utils.class(Dialogs.ConfigDialog)

function CMakeSettings:init(builder, options)
    builder:configure()

    Dialogs.ConfigDialog.init(self, builder, vim.tbl_extend("keep", {
        actions = {"Configure", "Assign Target"},

        actionselected = function(_, idx)
            if idx == 1 then
                builder:configure()
            elseif idx == 2 then
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
    }, options or { }))

    vim.api.nvim_command("wincmd p")
end

function CMakeSettings:assign_target(target)
    for _, d in ipairs(self:get_data()) do
        d.target = target
    end

    self:update() -- NOTE: Find a better implementation
end

return CMakeSettings
