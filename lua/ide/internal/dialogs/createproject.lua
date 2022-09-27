local Utils = require("ide.utils")
local Components = require("ide.ui.lib.components")
local Dialogs = require("ide.ui.lib.dialogs")

local CreateProjectDialog = Utils.class(Dialogs.Dialog)

function CreateProjectDialog:init(ide)
    self._ide = ide

    Dialogs.Dialog.init(self, "Create Project", {width = 50})

    self:set_components({
        Components.Input("Name:", nil, {key = "n", id = "name", width = "100%"}),
        {
            Components.Select("Type:", nil, {key = "t", id = "type", width = "50%", items = function() return self:_get_types() end}),
            Components.Select("Builder:", nil, {key = "b", id = "builder", col = "50%", width = "50%", items = function() return self:_get_builders() end}),
        },
        Components.Picker("Folder:", {key = "f", id = "folder", width = "100%", onlydirs = true}),
        Components.Button("Create", {key = "c", col = -1, event = function() self:accept() end})
    })
end

function CreateProjectDialog:on_accept(model)
    local ok, ProjectType = pcall(require, string.format("ide.projects.%s", model.type))

    if not ok then
        error(ProjectType)
        return
    end

    local p = ProjectType(self._ide.config, model.folder, model.name, model.builder)
    self._ide.projects[model.folder] = p
    self._ide.active = model.folder
    p:create()
    self._ide:pick_file(p:get_path(true))
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
