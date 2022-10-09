local Utils = require("ide.utils")
local Input = require("ide.ui.components.input")

local private = Utils.private_stash()
local Picker = Utils.class(Input)

function Picker:init(text, value, options)
    options = options or { }

    private[self] = {
        onlydirs = options.onlydirs == true,
        cwd = options.cwd,
    }

    Input.init(self, text, value, options)
end

function Picker:on_event(e)
    local PickerDialog = require("ide.ui.dialogs.picker")
    local fn = private[self].onlydirs == true and PickerDialog.select_folder or PickerDialog.select_file

    fn(function(choice)
        self:set_value(tostring(choice))
        e.update(tostring(choice))
    end, {cwd = private[self].cwd})
end

return Picker
