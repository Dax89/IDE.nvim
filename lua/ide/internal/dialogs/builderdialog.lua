local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")

local BuilderDialog = Utils.class(Dialogs.Dialog)

function BuilderDialog:init(builder, options)
    options = options or { }
    self.builder = builder
    self.project = builder.project
    self._showsave = options.showsave or false

    local title = options.title or (self.project:get_name() .. " - Settings")
    local dlgoptions = vim.tbl_extend("force", {width = 50}, options)
    Dialogs.Dialog.init(self, title, dlgoptions)
end

function BuilderDialog:set_components(components)
    components = vim.list_extend({{
        Components.Select("Mode:", self.project:get_mode(), {
            id = "mode",
            key = self.options.modekey or "m",
            width = "50%",
            change = function(_, v)
                self.project:set_mode(v)
            end,
            items = function()
                return self.builder:get_modes()
            end
        }),
        Components.Select("Target:", self.project:get_target(), {
            id = "target",
            key = self.options.targetkey or "t",
            col = "50%",
            width = "50%",
            change = function(_, v)
                self.project:set_target(v)
            end,
            items = function()
                return self.builder:get_targets()
            end}),

        }}, components or { })

    if self._showsave then
        table.insert(components, Components.Button("Save", {
            col = -1,
            event = function()
                self:accept()
            end
        }))
    end

    Dialogs.Dialog.set_components(self, components)
end

return BuilderDialog

