local Utils = require("ide.utils")
local Dialog = require("ide.ui.base.dialog")

local CreateProjectDialog = Utils.class(Dialog)

function CreateProjectDialog:init(ide)
    Dialog.init(self, nil, {width = 50, height = 7})

    self._ide = ide
    self:set_title("Create Project")

    self:set_model({
        {self:component("name", "text", "Name", "n"), self:component("type", "select", "Type", "t", { items = self:_get_types()})},
        self:component("folder", "folder", "Folder", "f"),
        {},
        self:component("_btncreate", "button", "Create Project", "<CR>", { align = "right", event = self.on_create}),
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

    local p = ProjectType(self._ide.config, self.data.folder, self.data.name)
    self._ide.projects[self.data.folder] = p
    self._ide.active = self.data.folder
    p:create()
    self._ide:pick_file(p:get_path(true))
    self:close()
end

function CreateProjectDialog:_get_types()
    local Path = require("plenary.path")
    local Scan = require("plenary.scandir")
    local types = Path:new(Utils.get_plugin_root(), "lua", "ide", "projects")

    return vim.tbl_map(function(t)
        return Utils.get_filename(t)
    end, Scan.scan_dir(tostring(types), {only_dirs = true, depth = 1}))
end

return CreateProjectDialog
