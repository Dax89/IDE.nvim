local Utils = require("ide.utils")
local Components = require("ide.ui.lib.components")
local Dialogs = require("ide.ui.lib.dialogs")

local CreateProjectDialog = Utils.class(Dialogs.Dialog)

function CreateProjectDialog:init(ide)
    Dialogs.Dialog.init(self, {width = 50, height = 6})

    self._ide = ide

    self:set_components({
        Components.Label("Create Project", {col = "50%"}),
        Components.HLine(),
        Components.Input("Name", nil, {id = "name", width = "100%"}),
        {
            Components.Select("Type", nil, {id = "type", width = "50%", items = function() return self:_get_types() end}),
            Components.Select("Builder", nil, {id = "builder", col = 25, width = "50%", items = function() return self:_get_builders() end}),
        },
        Components.Picker("Folder", {id = "folder", width = "100%", onlydirs = true}),
        Components.Button("Create", {col = -1, event = function() self:on_create() end})
    })
end

function CreateProjectDialog:on_create()
    if not self:validate_model() then
        return
    end

    local ok, ProjectType = pcall(require, string.format("ide.projects.%s", self.model.type))

    if not ok then
        error(ProjectType)
        return
    end

    local p = ProjectType(self._ide.config, self.model.folder, self.model.name, self.model.builder)
    self._ide.projects[self.model.folder] = p
    self._ide.active = self.model.folder
    p:create()
    self._ide:pick_file(p:get_path(true))
    self:close()
end

function CreateProjectDialog:on_model_changed(model, k, _, _)
    if k == "type" then
        model.builder = nil
    end
end

function CreateProjectDialog:_get_features(...)
    local Path = require("plenary.path")
    local Scan = require("plenary.scandir")
    local features = Path:new(Utils.get_plugin_root(), "lua", "ide", ...)

    return vim.tbl_map(function(t)
        return Utils.get_filename(t)
    end, Scan.scan_dir(tostring(features), {only_dirs = true, depth = 1}))
end

function CreateProjectDialog:_get_builders()
    return self.model.type and self:_get_features("projects", self.model.type, "builders") or { }
end

function CreateProjectDialog:_get_types()
    return self:_get_features("projects")
end

return CreateProjectDialog
