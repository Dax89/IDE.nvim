local Utils = require("ide.utils")
local Dialogs = require("ide.ui.lib.dialogs")
local Components = require("ide.ui.lib.components")

local CMakeSettings = Utils.class(Dialogs.Dialog)

function CMakeSettings:init(builder)
    Dialogs.Dialog.init(self, {width = 50, height = 5})

    self._builder = builder
    self._project = builder.project

    self:set_components({
        Components.Label(self._project:get_name() .. " - Settings", {width = "100%", align = "center"}),
        Components.HLine(),
        {
            Components.Select("Mode:", self._project:get_mode(), {
                id = "mode",
                width = "50%",
                change = function(_, v)
                    self._project:set_mode(v)
                end,
                items = function()
                    return self._builder:get_modes()
                end}),
            Components.Select("Target:", self._project:get_option("target"), {
                id = "target",
                col = "50%",
                width = "50%",
                change = function(_, v)
                    self._project:set_option("target", v)
                end,
                items = function()
                    return self._builder:get_targets()
                end}),
        },
        {},
        Components.Button("Run Configure", {
            col = 17,
            event = function()
                self._builder:configure()
            end}),
    })
end

return CMakeSettings
