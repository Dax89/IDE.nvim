local Utils = require("ide.utils")
local Dialog = require("ide.ui.base.dialog")

local CreateProjectDialog = Utils.class(Dialog)

function CreateProjectDialog:init(ide)
    Dialog.init(self, nil, {width = 50, height = 7})

    self._ide = ide
    self:set_title("Create Project")

    self:set_model({
        {id = "name", type = "text", label = "Name", key = "n"},
        {
            {id = "type", type = "select", label = "Type", key = "t", items = self._get_types},
            {id = "builder", type = "select", label = "Builder", key = "b", items = self._get_builders},
        },
        {id = "folder", type = "folder", label = "Folder", key = "f"},
        {},
        {id = "_btncreate", type = "button", label = "Create", key = "<CR>", align = "right", event = self.on_create}
    })
end

function CreateProjectDialog:on_create()
    if not self:check_required() then
        return
    end

    local ok, ProjectType = pcall(require, string.format("ide.projects.%s", self.data.type))
    if not ok then
        error(ProjectType)
        return
    end

    local p = ProjectType(self._ide.config, self.data.folder, self.data.name, self.data.builder)
    self._ide.projects[self.data.folder] = p
    self._ide.active = self.data.folder
    p:create()
    self._ide:pick_file(p:get_path(true))
    self:close()
end

function CreateProjectDialog:on_data_changed(data, k, _, _)
    if k == "type" then
        data.builder = nil
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
    return self.data.type and self:_get_features("projects", self.data.type, "builders") or { }
end

function CreateProjectDialog:_get_types()
    return self:_get_features("projects")
end

return CreateProjectDialog
