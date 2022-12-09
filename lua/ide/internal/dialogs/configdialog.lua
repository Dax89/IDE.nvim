local Utils = require("ide.utils")
local Cells = require("ide.ui.components.cells")
local Popups = require("ide.ui.popups")

local private = Utils.private_stash()
local ConfigDialog = Utils.class(Popups.TablePopup)

function ConfigDialog:init(builder, options)
    options = options or { }

    private[self] = {
        editable = options.editable ~= false,
        showcommand = options.showcommand ~= false,
        showarguments = options.showarguments ~= false,
        showworkingdir = options.showworkingdir ~= false,
        togglemode = options.togglemode ~= false,
        buildmode = options.buildmode ~= false,
        buildheader = vim.F.if_nil(options.buildheader, { }),
        runheader = vim.F.if_nil(options.runheader, { }),
        change = options.change
    }

    self.builder = builder
    self.project = builder.project

    Popups.TablePopup.init(self, self:_get_header(), self:_get_data(), self:_get_title(),
    {
        actions = options.actions,
        actionselected = options.actionselected,

        buttons = function()
            if private[self].togglemode then
                return private[self].buildmode and {"Run Config"} or {"Build Config"}
            end

            return { }
        end,

        buttonclick = function()
            self:_update_config(self:get_data())
            private[self].buildmode = not private[self].buildmode
            self:set_title(self:_get_title())
            self:reload(self:_get_header(), self:_get_data())
        end,

        cellchange = function(_, arg)
            if arg.header.name == "selected" then
                for i, r in ipairs(arg.data) do
                    if i ~= arg.index then
                        r.selected = false
                    end
                end
            elseif arg.header.name == "name" then
                arg.value = self:_get_unique_name(arg.value, arg.data, arg.index)
            end
        end,

        add = function(_, arg)
            arg.row.name = self:_get_unique_name("newconfig", arg.data, arg.index)
        end,

        change = function(_, v)
            self:_update_config(v)
        end
    })
end

function ConfigDialog:_update_config(data)
    if private[self].buildmode then
        self.project:reset_config()
    else
        self.project:reset_runconfig()
    end

    for _, cfg in ipairs(data) do
        if private[self].buildmode then
            self.project:set_config(cfg.name, cfg)
        else
            self.project:set_runconfig(cfg.name, cfg)
        end

        if cfg.selected then
            if private[self].buildmode then
                self.project:set_selected_config(cfg.name)
            else
                self.project:set_selected_runconfig(cfg.name)
            end
        end
    end

    if vim.is_callable(private[self].change) then
        private[self].change(self, data, private[self].buildmode) -- Forward event
    end
end

function ConfigDialog:_get_title()
    if private[self].buildmode then
       return self.project:get_name() .. " - Build Configuration"
    end

    return self.project:get_name() .. " - Run Configuration"
end

function ConfigDialog:_check_editable_cell(celltype)
    return private[self].editable and celltype or Cells.LabelCell
end

function ConfigDialog:_get_build_header()
    return vim.list_extend({
        {name = "selected", label = "Selected", type = Cells.CheckCell},
        {name = "name", label = "Name", type = self:_check_editable_cell(Cells.InputCell)},
    }, private[self].buildheader or { })
end

function ConfigDialog:_get_build_data()
    local data = vim.tbl_values(self.project:get_config())
    local selcfg = self.project:get_selected_config()

    for _, cfg in ipairs(data) do
        if selcfg and cfg.name == selcfg.name then
            cfg.selected = true
            break
        end
    end

    return data
end

function ConfigDialog:_get_run_header()
    local fullheader = vim.list_extend({
        {name = "selected", label = "Selected", type = Cells.CheckCell},
        {name = "name", label = "Name", type = self:_check_editable_cell(Cells.InputCell)},
    }, private[self].runheader or { })

    if private[self].showcommand then
        table.insert(fullheader, {
            name = "command",
            label = "Command",
            type = self:_check_editable_cell(Cells.InputCell)
        })
    end

    if private[self].showarguments then
        table.insert(fullheader, {
            name = "arguments",
            label = "Arguments",
            type = self:_check_editable_cell(Cells.InputCell)
        })
    end

    if private[self].showworkingdir then
        table.insert(fullheader, {
            name = "cwd",
            label = "Working Dir",
            type = self:_check_editable_cell(Cells.PickerCell),
            options = {onlydirs = true}
        })
    end

    return fullheader
end

function ConfigDialog:_get_run_data()
    local data = vim.tbl_values(self.project:get_runconfig())
    local selcfg = self.project:get_selected_runconfig()

    for _, cfg in ipairs(data) do
        if selcfg and cfg.name == selcfg.name then
            cfg.selected = true
            break
        end
    end

    return data
end

function ConfigDialog:_get_header()
    return private[self].buildmode and self:_get_build_header() or self:_get_run_header()
end

function ConfigDialog:_get_data()
    return private[self].buildmode and self:_get_build_data() or self:_get_run_data()
end

function ConfigDialog:_get_unique_name(name, data, skipidx)
    local n, c, names = name, 0, vim.tbl_map(function(r)
        return r.name or ""
    end, data)

    table.remove(names, skipidx) -- Remove current row

    while vim.tbl_contains(names, n) do
        c = c + 1
        n = name .. "_" .. tostring(c)
    end

    c = 0

    local getcfg = private[self].buildmode and self.project.get_config or self.project.get_runconfig

    while getcfg(self.project, n) do
        n = name .. "_" .. tostring(c)
        c = c + 1
    end

    return n
end

function ConfigDialog:on_accept()
    Popups.TablePopup.on_accept(self)
    self.project:write()
end

return ConfigDialog

