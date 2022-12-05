local Async = require("plenary.async")
local Utils = require("ide.utils")
local Components = require("ide.ui.components")
local Dialogs = require("ide.ui.dialogs")
local Screen = require("ide.ui.utils.screen")
local Log = require("ide.log")

local CreateProjectDialog = Utils.class(Dialogs.TabsDialog)

function CreateProjectDialog:init(ide)
    self.ide = ide

    Dialogs.TabsDialog.init(self, {"Configuration", "Location"}, "Create Project", {
        width = Screen.get_width("60%"),
        wizard = true,
    })

    self:set_components({
        Configuration = {
            Components.Input("Name:", nil, {key = "n", id = "name", width = "100%"}),
            {
                Components.Select("Type:", nil, {key = "t", id = "type", width = "100%", items = function() return self:_get_types() end}),
                Components.Select("Builder:", nil, {key = "b", id = "builder", col = "50%", width = "50%", items = function() return self:_get_builders() end}),
            },
            Components.Select("Template:", nil, {key = "T", id = "template", width = "100%", optional = true, items = function() return self:_get_templates() end}),
        },

        Location = {
            Components.Picker("Create In:", nil, {key = "f", id = "folder", width = "100%", onlydirs = true}),
            self.ide:has_integration("git") and Components.CheckBox("Initialize GIT Repo", false, {key = "r", id = "git", width = "100%"}) or nil,
        },
    })
end

function CreateProjectDialog:_get_templates()
    local modeldata = self:get_model().data

    if Utils.if_nilempty(modeldata.type) or Utils.if_nilempty(modeldata.builder) then
        return {}
    end

    local ok, ProjectType = pcall(require, "ide.projects." .. modeldata.type)

    if ok then
        local res, templates = {}, ProjectType.get_templates(modeldata.type, modeldata.builder)

        if type(templates) == "table" then
            for k, v in pairs(templates) do
                table.insert(res, {
                    text = v.name,
                    value = k
                })
            end

            return res
        end
    end

    return {}
end

function CreateProjectDialog:on_accept(data)
    local ok, ProjectType = pcall(require, "ide.projects." .. data.type)

    if ok then
        local templates = ProjectType.get_templates(data.type, data.builder)
        data.templatedata = templates[data.template]

        local p = ProjectType(self.ide.config, data.folder, data.name, data.builder)

        Async.run(function()
            p:create(data)
            p:write(true) -- Save project file
        end, function()
            local rootpath = p:get_path(true)
            self.ide.projects[rootpath] = p
            self.ide.active = rootpath

            Log.debug("CreateProjectDialog:on_accept(): Creating project '" .. data.name .. "' in " .. rootpath)

            if data.git == true then
                Log.debug("CreateProjectDialog:on_accept(): Initializing git repo in " .. rootpath)
                Utils.os_execute("git", {"init", rootpath})
            end

            vim.schedule(function()
                self.ide:update_recents(p)
                self.ide:pick_file(rootpath)
            end)
        end)
    end
end

function CreateProjectDialog:on_model_changed(model, k)
    if k == "type" then
        local builders = self:_get_builders()
        model.builder = vim.tbl_islist(builders) and not vim.tbl_isempty(builders) and builders[1] or nil
        model.template = nil
    end

    if (k == "type" or k == "builder") and model.type then
        local ok, ProjectType = pcall(require, "ide.projects." .. model.type)
        model.template = ok and self:_get_default_template(ProjectType, model.type, model.builder) or nil
    end
end

function CreateProjectDialog:_get_default_template(project, t, b)
    local templates = project.get_templates(t, b)

    if type(templates) == "table" then
        local keys = vim.tbl_keys(templates)

        if #keys == 1 then
            return keys[1]
        end

        for n, v in pairs(templates) do
            if v.default == true then
                return n
            end
        end
    end

    return nil
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
    local modeldata = self:get_model().data
    return modeldata.type and #modeldata.type > 0 and self:_get_features("projects", modeldata.type, "builders") or { }
end

function CreateProjectDialog:_get_types()
    return self:_get_features("projects")
end

return CreateProjectDialog
