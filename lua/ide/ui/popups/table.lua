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
        editable = vim.F.if_nil(options.editable, true),
        fullrow = vim.F.if_nil(options.fullrow, false),
        selected = options.selected,
        change = options.change,
        remove = options.remove,
        add = options.add,
        rowindex = -1,
        colindex = -1,
    }

    self.width = options.width
    self.height = vim.F.if_nil(options.height, math.max(math.min(2, #private[self].header + #private[self].data), 12))

    Dialog.init(self, title, {
        zindex = 50
    })

    self:_update_table()
    self:map("a", function() self:on_add() end, {builtin = true})
    self:map("d", function() self:on_remove() end, {builtin = true})
    self:map({"j", "<Down>"}, function() self:on_move_down() end, {builtin = true})
    self:map({"k", "<Up>"}, function() self:on_move_up() end, {builtin = true})
    self:map({"h", "<Left>"}, function() self:on_move_left() end, {builtin = true})
    self:map({"l", "<Right>"}, function() self:on_move_right() end, {builtin = true})
end

function TablePopup:get_data()
    return private[self].data
end

function TablePopup:get_current_row()
    local rowidx = private[self].rowindex
    return rowidx >= 0 and private[self].data[rowidx + 1] or nil
end

function TablePopup:get_current_col()
    local colidx = private[self].colindex

    if private[self].fullrow or colidx < 0 then
        return nil
    end

    local row = self:get_current_row()
    local h = private[self].header[colidx + 1]

    if row and h and h.name then
        return row[h.name]
    end

    return nil
end

function TablePopup:on_add()
    if not private[self].editable then
        return
    end

    local newrow = { }

    if vim.is_callable(private[self].add) then
        newrow = private[self].add(self, newrow, {
            row = private[self].rowindex,
            col = private[self].colindex
        }) or { }
    end

    assert(vim.tbl_islist(newrow))
    table.insert(private[self].data, 1, newrow)
    self:_update_table()
end

function TablePopup:on_accept()
    if vim.is_callable(private[self].change) then
        private[self].change(self, private[self].data)
    end
end

function TablePopup:on_remove()
    if not private[self].editable then
        return
    end

    if not vim.tbl_isempty(private[self].data) then
        local canremove = true

        if vim.is_callable(private[self].remove) then
            canremove = private[self].remove(self, self:get_current_item(), self.index) ~= false
        end

        if canremove then
            table.remove(private[self].data, private[self].rowindex + 1)
            self:_update_index(self.index, true) -- Recalculate index, if needed
        end
    end
end

function TablePopup:on_move_up()
    if not vim.tbl_isempty(private[self].data) then
        self:_update_index(private[self].rowindex - 1)
    end

end

function TablePopup:on_move_down()
    if not vim.tbl_isempty(private[self].data) then
        self:_update_index(private[self].rowindex + 1)
    end
end

function TablePopup:on_move_left()
    if private[self].fullrow then
        return
    end

    if not vim.tbl_isempty(private[self].data) and not vim.tbl_isempty(private[self].header) then
        self:_update_index(nil, private[self].colindex - 1)
    end
end

function TablePopup:on_move_right()
    if private[self].fullrow then
        return
    end

    if not vim.tbl_isempty(private[self].data) and not vim.tbl_isempty(private[self].header) then
        self:_update_index(nil, private[self].colindex + 1)
    end
end

function TablePopup:_update_table()
    if vim.tbl_isempty(private[self].header) then
        error("TablePopup: Header is empty")
    end

    local startcol, w = 0, math.floor(self.width / #private[self].header)
    self:set_cursor(private[self].rowindex + 2, private[self].colindex * w)

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

    for rowidx, rowdata in ipairs(private[self].data) do
        local row = { }
        startcol = 0

        for colidx, h in pairs(private[self].header) do
            if h.name then
                local options = {
                    col = startcol,
                    width = w,
                    showlabel = false,
                    showicon = false,
                    align = "center",
                }

                local v, c = rowdata[h.name], nil

                local change = function(value)
                    if private[self].editable then
                        rowdata[h.name] = value
                        self:_update_table()
                    end
                end

                if vim.is_callable(h.type) then
                    c = h.type(self, {
                        value = v,
                        header = h,
                        change = change,
                        row = rowdata,
                        options = options,
                        label = h.label or h.name or "",
                    })
                end

                if not c then
                    c = Components.Label(vim.F.if_nil(v, ""), options)
                end

                if private[self].rowindex + 1 == rowidx and (private[self].fullrow or private[self].colindex + 1 == colidx) then
                    c.foreground = "selected"
                    c.background = "selected"
                end

                startcol = startcol + w
                table.insert(row, c)
            end
        end

        table.insert(t, row)
    end

    table.insert(t, 1, header)
    self:fill_components(t, self.height - 4)

    table.insert(t, Components.Button("Accept", {
        key = "A",
        col = -2,
        event = function() self:accept() end
    }))

    self:set_components(t)
    self:render()
end

function TablePopup:_update_index(rowindex, colindex, force)
    local oldrowindex, oldcolindex = nil, nil

    if rowindex ~= nil then
        oldrowindex = private[self].rowindex

        if rowindex >= #private[self].data then
            rowindex = #private[self].data - 1
        elseif rowindex <= 0 then
            rowindex = 0

            if private[self].colindex == -1 then
                colindex = 0
            end
        end
    end

    if not private[self].fullrow and colindex ~= nil then
        oldrowindex = private[self].colindex

        if colindex >= #private[self].header then
            colindex = #private[self].header - 1
        elseif colindex <= 0 then
            colindex = 0

            if private[self].rowindex == -1 then
                rowindex = 0
            end
        end
    end

    local changed = false

    if force or (rowindex ~= nil and rowindex ~= oldrowindex) then
        private[self].rowindex = rowindex
        changed = true
    end

    if force or (colindex ~= nil and colindex ~= oldcolindex) then
        private[self].colindex = colindex
        changed = true
    end

    if changed then
        self:_update_table()

        if vim.is_callable(private[self].selected) then
            private[self].selected(self, self:get_current_row(), self:get_current_col())
        end
    end
end

return TablePopup