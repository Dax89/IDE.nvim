local Utils = require("ide.utils")
local Input = require("ide.ui.lib.components.input")

local Picker = Utils.class(Input)

function Picker:init(text, options)
    options = options or { }
    Input.init(self, text, nil, options)

    self._onlydirs = options.onlydirs == true
    self._cwd = options.cwd
end

function Picker:on_event(e)
    local PickerView = require("ide.ui.picker")
    local fn = self._onlydirs == true and PickerView.select_folder or PickerView.select_file

    fn(function(choice)
        self:set_value(tostring(choice))
        e.update(tostring(choice))
    end, {cwd = self._cwd})
end

return Picker
