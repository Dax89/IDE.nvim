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
            Components.Input("License:", package.license, {id = "license", width = "50%"}),
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
                    return vim.tbl_keys(package.dependencies or { })
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
                    return vim.tbl_keys(package.devDependencies or { })
                end,
                change = function(_, data) self:install_dependencies(data, true) end,
            }),

            Components.Button("Configuration", {
                key = "c",
                col = 34,
                background = "secondary",

                click = function()
                    ConfigDialog(self.builder, nil, {showcommand = true}):popup()
                end,

                data = function()
                    local data = { }

                    for name, command in pairs(package.scripts or { }) do
                        table.insert(data, {name = name, command = command})
                    end

                    return data
                end,
                change = function() self.builder:config_to_scripts() end
            }),

            Components.Button("Save", {col = -1, click = function() self:accept() end}),
        }
    })
end

function NodeSettings:uninstall_dependencies(deps, dev)
    local args = {
        "uninstall",
        dev and "--save-dev" or "--save",
    }

    args = vim.list_extend(args, deps)

    self.project:new_job("npm", args, {
        title = "Uninstalling Dependencies...",
        state = "configure",
        src = true,
      })
end

function NodeSettings:install_dependencies(items, dev)
    local package = self.builder.read_package()
    local deps = dev and package.devDependencies or package.dependencies

    local toremove = vim.tbl_filter(function(dep)
        return vim.tbl_contains(items, dep)
    end, vim.tbl_keys(deps or { }))

    local args = {
        "install",
        dev and "--save-dev" or "--save"
    }

    args = vim.list_extend(args, items)

    self.project:new_job("npm", args, {
        title = "Installing Dependencies...",
        state = "configure",
        src = true,
        onexit = function()
            if not vim.tbl_isempty(toremove) then
                self:uninstall_dependencies(toremove)
            end
        end})
end

function NodeSettings:on_accept(model)
    self.builder:write_package(vim.tbl_extend("force", self.builder:read_package(), model:get_data()))
end

return NodeSettings
