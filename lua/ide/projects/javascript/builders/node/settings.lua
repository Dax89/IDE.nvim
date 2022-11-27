local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")
local Cells = require("ide.ui.components.cells")
local ConfigDialog = require("ide.internal.dialogs.configdialog")

local NodeSettings = Utils.class(Dialogs.Dialog)

function NodeSettings:init(builder)
    self.builder = builder
    self.project = builder.project

    local package = builder:read_package()

    Dialogs.Dialog.init(self, self.project:get_name() .. " - Settings", {width = 60})

    self:set_components({
        {
            Components.Input("Name:", package.name, {id = "name", width = "50%"}),
            Components.Input("Version:", package.version, {id = "version", col = "50%", width = "50%"}),
        },
        {
            Components.Input("License:", package.license, {id = "license", width = "50%", optional = true}),
            Components.Input("Author:", package.author, {id = "author", col = "50%", width = "50%", optional = true}),
        },
        Components.Input("Description:", package.description, {id = "description", width = "100%", optional = true}),
        {},
        {
            Components.ListView("Dependencies", {
                key = "d",
                col = 0,
                background = "secondary",
                view = {width = 40},
                unique = true,
                items = function()
                    return vim.tbl_keys(self.builder:read_package().dependencies or { })
                end,
                change = function(_, data) self:install_dependencies(data) end
            }),

            Components.ListView("Dev Dependencies", {
                key = "D",
                col = 15,
                background = "secondary",
                view = {width = 40},
                unique = true,
                items = function()
                    return vim.tbl_keys(self.builder:read_package().devDependencies or { })
                end,
                change = function(_, data) self:install_dependencies(data, true) end,
            }),

            Components.Button("Configuration", {
                key = "c",
                col = 34,
                background = "secondary",

                click = function()
                    ConfigDialog(self.builder, {
                        buildmode = false,
                        togglemode = false,
                        showworkingdir = false,
                        showarguments = false,
                    }):popup(function()
                        self.builder:config_to_scripts()
                    end)
                end,
            }),

            Components.Button("Save", {
                key = "A",
                col = -1,
                click = function()
                    self:sync_dependencies()
                    self:accept()
                end
            }),
        }
    })
end

function NodeSettings:uninstall_dependencies(deps, dev, onexit)
    if vim.tbl_isempty(deps) then
        if vim.is_callable(onexit) then
            onexit()
        end

        return
    end

    local args = vim.list_extend({
        "uninstall",
        dev and "--save-dev" or "--save",
    }, deps)

    self.project:new_job("npm", args, {
        title = "Uninstalling Dependencies...",
        state = "configure",
        src = true,
        onexit = onexit,
      })
end

function NodeSettings:sync_dependencies()
    local package = self.builder:read_package()

    self:install_dependencies(vim.tbl_keys(package.devDependencies or {}), true, function()
        self:install_dependencies(vim.tbl_keys(package.dependencies or {}), false)
    end)
end

function NodeSettings:install_dependencies(items, dev, onexit)
    local package = self.builder:read_package()
    local deps = dev and package.devDependencies or package.dependencies

    local toremove = vim.tbl_filter(function(dep)
        return not vim.tbl_contains(items, dep)
    end, vim.tbl_keys(deps or { }))

    self:uninstall_dependencies(toremove, dev, function()
        local args = vim.list_extend({
            "install",
            dev and "--save-dev" or "--save"
        }, items)

        self.project:new_job("npm", args, {
            title = "Installing Dependencies...",
            state = "configure",
            src = true,
            onexit = onexit
        })
    end)
end

function NodeSettings:on_accept(model)
    self.builder:write_package(vim.tbl_extend("force", self.builder:read_package(), model:get_data()))
end

return NodeSettings
