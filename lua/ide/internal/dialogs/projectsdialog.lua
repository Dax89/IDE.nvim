local Utils = require("ide.utils")
local Screen = require("ide.ui.utils.screen")
local Table = require("ide.ui.popups.table")
local Path = require("plenary.path")

local ProjectsDialog = Utils.class(Table)

function ProjectsDialog:init(ide, options)
    local header = {
        {name = "name", label = "Name", align = "right"},
        {name = "type", label = "Type"},
        {name = "builder", label = "Builder", align = "left"},
    }

    local recents = ide:load_recents()

    local data = vim.tbl_map(function(r)
        local d = Utils.read_json(Path:new(r.root, ide.config.project_file))
        d.builder = vim.F.if_nil(d.builder, "nvide")
        d.root = r.root
        return d
    end, Utils.list_reverse(recents))

    Table.init(self, header, data, "Projects", vim.tbl_extend("keep", {
        width = Screen.get_width("60%"),
        showaccept = false,
        selectionrequired = true,
        fullrow = true,
        editable = false,
    }, options or { }))
end

return ProjectsDialog
