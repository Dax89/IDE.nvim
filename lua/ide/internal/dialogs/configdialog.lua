local Utils = require("ide.utils")
local Cells = require("ide.ui.components.cells")
local Popups = require("ide.ui.popups")

local ConfigDialog = Utils.class(Popups.TablePopup)

function ConfigDialog:init(builder, header, options)
    options = options or { }

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

    Popups.TablePopup.init(self, fullheader, data,
    vim.F.if_nil(options.title, self.project:get_name() .. " - Configuration"),
    vim.tbl_extend("force", options, {
        cellchanged = function(_, arg)
            if arg.header.name == "selected" then
                for i, r in ipairs(arg.data) do
                    if i ~= arg.index then
                        r.selected = false
                    end
                end
            end
        end,

        changed = function(_, v)
            for _, cfg in ipairs(v) do
                self.project:set_config(cfg.name, cfg)

                if cfg.selected then
                    self.project:set_selected_config(cfg.name)
                end
            end

            if vim.is_callable(options.changed) then
                options.changed(self, v) -- Forward event
            end
        end
    }))
end

function ConfigDialog:on_accept()
    Popups.TablePopup.on_accept(self)
    self.project:write()
end

return ConfigDialog

