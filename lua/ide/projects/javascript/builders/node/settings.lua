local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")
local Path = require("plenary.path")

local NodeSettings = Utils.class(Dialogs.Dialog)

function NodeSettings:init(builder)
    self.builder = builder
    self.project = builder.project
    self.package = self:read_package()

    Dialogs.Dialog.init(self, self.project:get_name() .. " - Settings", {width = 60})

    self:set_components({
        {
            Components.Input("Name:", self.package.name, {id = "name", width = "50%"}),
            Components.Input("Version:", self.package.version, {id = "version", col = "50%", width = "50%"}),
        },
        {
            Components.Input("License:", self.package.license, {id = "license", width = "50%"}),
            Components.Input("Author:", self.package.author, {id = "author", col = "50%", width = "50%", optional = true}),
        },
        Components.Input("Description:", self.package.description, {id = "description", width = "100%", optional = true}),
        {},
        {
            Components.ListView("Dependencies", {
                col = 0,
                background = "secondary",
                unique = true,
                items = function()
                    return vim.tbl_keys(self.package.dependencies or { })
                end,
                remove = function(_, dep) self:uninstall_dependency(dep, false) end,
                selected = function(c) self:install_dependencies(c) end
            }),

            Components.ListView("Dev Dependencies", {
                col = 15,
                background = "secondary",
                unique = true,
                items = function()
                    return vim.tbl_keys(self.package.devDependencies or { })
                end,
                remove = function(_, dep) self:uninstall_dependency(dep, true) end,
                selected = function(c) self:install_dependencies(c, true) end,
            }),

            -- Components.ListView("Scripts", {
            --     col = 34,
            --     background = "secondary",
            --     items = function()
            --         return vim.tbl_keys(self.package.scripts or { })
            --     end,
            --     selected = function(c) self:on_scripts_selected(c) end
            -- }),

            Components.Button("Save", {col = -1, event = function() self:accept() end}),
        }
    })
end

function NodeSettings:uninstall_dependency(dep, dev)
    local args = {
        "uninstall",
        dev and "--save-dev" or "--save",
        dep
    }

    self.project:new_job("npm", args, {
        title = "Installing Dependency...",
        state = "configure",
        src = true,
        onexit = function()
          self.package = self:read_package()
      end})
end

function NodeSettings:install_dependencies(listview, dev)
    local args = {
        "install",
        dev and "--save-dev" or "--save"
    }

    args = vim.list_extend(args, listview.items)

    self.project:new_job("npm", args, {
        title = "Installing Dependencies...",
        state = "configure",
        src = true,
        onexit = function()
          self.package = self:read_package()
      end})
end

-- function NodeSettings:on_scripts_selected(listview)
-- end

function NodeSettings:on_accept(model)
    self.package = vim.tbl_extend("force", self.package, model:get_data())
    Utils.write_json(Path:new(self.project:get_path(), "package.json"), self.package)
end

function NodeSettings:read_package()
    return Utils.read_json(Path:new(self.project:get_path(), "package.json"))
end

return NodeSettings
