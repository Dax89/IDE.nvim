local Utils = require("ide.utils")
local Dialog = require("ide.ui.dialogs.dialog")
local Components = require("ide.ui.components")

local private = Utils.private_stash()
local TablePopup = Utils.class(Dialog)

function TablePopup:init(header, data, title, options)
    options = options or { }

    private[self] = {
        header = vim.F.if_nil(header, { }),
        data = vim.F.if_nil(data, { }),
    }

    self.index = 0
    self.width = options.width
    self.height = vim.F.if_nil(options.height, math.max(math.min(2, #private[self].header + #private[self].data), 10))

    Dialog.init(self, title, {
        showhelp = false,
        zindex = 50
    })

    self:_update_table()
    self:map("a", function() self:on_add() end, {builtin = true})
    self:map("d", function() self:on_remove() end, {builtin = true})
    self:map("e", function() self:on_edit() end, {builtin = true})
    self:map({"j", "<Down>"}, function() self:on_move_down() end, {builtin = true})
    self:map({"k", "<Up>"}, function() self:on_move_up() end, {builtin = true})
    self:map({"h", "<Left>"}, function() self:on_move_left() end, {builtin = true})
    self:map({"l", "<Right>"}, function() self:on_move_right() end, {builtin = true})
end

function TablePopup:on_add()
end

function TablePopup:on_remove()
end

function TablePopup:on_edit()
end

function TablePopup:on_move_up()
end

function TablePopup:on_move_down()
end

function TablePopup:on_move_left()
end

function TablePopup:on_move_right()
end

function TablePopup:_update_table()
    if vim.tbl_isempty(private[self].header) then
        error("TablePopup: Header is empty")
    end

    local startcol, w = 0, math.floor(self.width / #private[self].header)

    local t, header = { }, vim.tbl_map(function(h)
        local c = Components.Label(h.label or h.name, {
            col = startcol,
            width = w,
            foreground = "cursor",
            background = "cursor",
            align = "center",
        })

        startcol = startcol + w
        return c
    end, private[self].header)

    for _, rowdata in ipairs(private[self].data) do
        local row = { }
        startcol = 0

        for _, h in pairs(private[self].header) do
            if h.name then
                local options = {
                    col = startcol,
                    width = w,
                    align = "center"
                }

                local v, c = rowdata[h.name], nil

                local change = function(value)
                    rowdata[h.name] = value
                    self:_update_table()
                end

                if vim.is_callable(h.type) then
                    c = h.type(self, v, change, options, rowdata)
                end

                if not c then
                    c = Components.Label(tostring(v), options)
                end

                startcol = startcol + w
                table.insert(row, c)
            end
        end

        table.insert(t, row)
    end

    table.insert(t, 1, header)
    self:set_components(t)
    self:render()
end

return TablePopup
