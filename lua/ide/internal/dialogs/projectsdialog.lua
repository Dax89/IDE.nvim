local Utils = require("ide.utils")
local Table = require("ide.ui.popups.table")
local Path = require("plenary.path")

local private = Utils.private_stash()
local ProjectsDialog = Utils.class(Table)

function ProjectsDialog:init(ide, options)
    private[self] = {
        ide = ide
    }

    local header = {
        {name = "name", label = "Name", align = "right"},
        {name = "type", label = "Type"},
        {name = "builder", label = "Builder", align = "left"},
    }

    local recents = ide:load_recents()

    local data = vim.tbl_map(function(r)
        local d = Utils.read_json(Path:new(r.root, ide.config.project_file))
        d.root = r.root
        return d
    end, Utils.list_reverse(recents))

    Table.init(self, header, data, "Projects", vim.tbl_extend("keep", {
        showbutton = false,
        fullrow = true,
    }, options or { }))
end

return ProjectsDialog
