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
                key = "d",
                col = 0,
                background = "secondary",
                view = {width = 40},
                unique = true,
                items = function()
                    return vim.tbl_keys(self.package.dependencies or { })
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
                    return vim.tbl_keys(self.package.devDependencies or { })
                end,
                change = function(_, data) self:install_dependencies(data, true) end,
            }),

            Components.TableView("Scripts", {
                key = "s",
                col = 34,
                background = "secondary",
                view = {width = 80},
                header = {
                    {
                        label = "Name",
                        name = "name",
                        type = function(_, arg)
                            arg.options.change = function(_, v) arg.change(v) end
                            return Components.Input(arg.label, arg.value, arg.options)
                        end
                    },
                    {
                        label = "Command",
                        name = "command",
                        type = function(_, arg)
                            arg.options.change = function(_, v) arg.change(v) end
                            arg.options.align = "left"
                            return Components.Input(arg.label, arg.value, arg.options)
                        end
                    },
                },
                data = function()
                    local data = { }

                    for name, command in pairs(self.package.scripts or { }) do
                        table.insert(data, {name = name, command = command})
                    end

                    return data
                end,
                change = function(_, c) self:update_scripts(c) end
            }),

            Components.Button("Save", {col = -1, event = function() self:accept() end}),
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
        onexit = function()
          self.package = self:read_package()
      end})
end

function NodeSettings:install_dependencies(items, dev)
    local deps = dev and self.package.devDependencies or self.package.dependencies

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
            if vim.tbl_isempty(toremove) then
                self.package = self:read_package()
            else
                self:uninstall_dependencies(toremove)
            end
        end})
end

function NodeSettings:update_scripts(scripts)
    self.package.scripts = { }

    for _, row in ipairs(scripts) do
        self.package.scripts[row.name] = row.command
    end

    self:write_package()
end

function NodeSettings:on_accept(model)
    self.package = vim.tbl_extend("force", self.package, model:get_data())
    self:write_package()
end

function NodeSettings:read_package()
    return Utils.read_json(Path:new(self.project:get_path(), "package.json"))
end

function NodeSettings:write_package()
    Utils.write_json(Path:new(self.project:get_path(), "package.json"), self.package)
end

return NodeSettings
