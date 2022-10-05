local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")

local private = Utils.private_stash()
local BuilderDialog = Utils.class(Dialogs.Dialog)

function BuilderDialog:init(builder, options)
    options = options or { }

    private[self] = {
        showsave = vim.F.if_nil(options.save, false),
        showrunargs = vim.F.if_nil(options.runargs, false),
        modekey = options.modekey,
        targetkey = options.targetkey,
    }

    self.builder = builder
    self.project = builder.project

    local title = options.title or (self.project:get_name() .. " - Settings")
    local dlgoptions = vim.tbl_extend("force", {width = 50}, options)
    Dialogs.Dialog.init(self, title, dlgoptions)
end

function BuilderDialog:set_components(components)
    local builtins = {{
        Components.Select("Mode:", self.project:get_mode(), {
            id = "mode",
            key = private[self].modekey or "m",
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
            key = private[self].targetkey or "t",
            col = "50%",
            width = "50%",
            change = function(_, v)
                self.project:set_target(v)
            end,
            items = function()
                return self.builder:get_targets()
            end}),
        }
    }

    if private[self].showrunargs then
        table.insert(builtins, Components.Input("Run Arguments:", self.project:get_runargs(self.project:get_target()), {
            id = "runargs",
            width = "100%",
            optional = true,
            change = function(_, v)
                self.project:set_runargs(self.project:get_target(), v)
            end
        }))
    end

    components = vim.list_extend(builtins, components or { })

    if private[self].showsave then
        table.insert(components, Components.Button("Save", {
            col = -1,
            event = function()
                self:accept()
            end
        }))
    end

    Dialogs.Dialog.set_components(self, components)
end

function BuilderDialog:on_accept()
    self.project:write()
end

function BuilderDialog:on_model_changed(model, k, v, _)
    if private[self].showrunargs and (k == "target") then
        model.runargs = self.project:get_runargs(v)
    end
end

return BuilderDialog

