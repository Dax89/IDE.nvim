local Utils = require("ide.utils")
local Cells = require("ide.ui.components.cells")
local Popups = require("ide.ui.popups")

local private = Utils.private_stash()
local ConfigDialog = Utils.class(Popups.TablePopup)

function ConfigDialog:init(builder, header, options)
    options = options or { }

    private[self] = {
        showcommand = options.showcommand == true
    }

    self.builder = builder
    self.project = builder.project

    local data = vim.tbl_values(self.project:get_config())
    local selcfg = self.project:get_selected_config()

    for _, cfg in ipairs(data) do
        if selcfg and cfg.name == selcfg.name then
            cfg.selected = true
            break
        end
    end

    local fullheader = vim.list_extend({
        {name = "selected", label = "Selected", type = Cells.CheckCell},
        {name = "name", label = "Name", type = Cells.InputCell},
    }, header or { })

    if private[self].showcommand then
        fullheader = vim.list_extend(fullheader, {
            {name = "command", label = "Command", type = Cells.InputCell},
        })
    end

    fullheader = vim.list_extend(fullheader, {
        {name = "cwd", label = "Working Dir", type = Cells.PickerCell, options = {onlydirs = true}},
    })

    Popups.TablePopup.init(self, fullheader, data,
    vim.F.if_nil(options.title, self.project:get_name() .. " - Configuration"),
    vim.tbl_extend("force", options, {
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
            self.project:reset_config()

            for _, cfg in ipairs(v) do
                self.project:set_config(cfg.name, cfg)

                if cfg.selected then
                    self.project:set_selected_config(cfg.name)
                end
            end

            if vim.is_callable(options.change) then
                options.change(self, v) -- Forward event
            end
        end
    }))
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

    while self.project:get_config(n) do
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

