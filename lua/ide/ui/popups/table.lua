local Utils = require("ide.utils")
local Dialog = require("ide.ui.dialogs.dialog")
local Base = require("ide.ui.base")
local Components = require("ide.ui.components")
local Cells = require("ide.ui.components.cells")

local private = Utils.private_stash()
local TablePopup = Utils.class(Dialog)

function TablePopup:init(header, data, title, options)
    options = options or { }

    self.title = title

    private[self] = {
        header = vim.F.if_nil(header, { }),
        data = vim.F.if_nil(data, { }),
        showaccept = vim.F.if_nil(options.showaccept, true),
        editable = vim.F.if_nil(options.editable, true),
        fullrow = vim.F.if_nil(options.fullrow, false),
        selectionrequired = vim.F.if_nil(options.selectionrequired, false),
        accepttext = vim.F.if_nil(options.accepttext, "Accept"),
        actiontext = vim.F.if_nil(options.actiontext, "Actions"),
        actionselected = options.actionselected,
        actions = options.actions,
        cellchanged = options.cellchanged,
        selected = options.selected,
        changed = options.changed,
        removed = options.removed,
        added = options.added,
        rowindex = -1,
        colindex = -1,
    }

    self.width = options.width
    self.height = vim.F.if_nil(options.height, math.max(math.min(2, #private[self].header + #private[self].data), 12))

    Dialog.init(self, title, {
        zindex = 50
    })

    self:update()
    self:map("a", function() self:on_add() end, {builtin = true})
    self:map("d", function() self:on_remove() end, {builtin = true})
    self:map({"j", "<Down>"}, function() self:on_move_down() end, {builtin = true})
    self:map({"k", "<Up>"}, function() self:on_move_up() end, {builtin = true})
    self:map({"h", "<Left>"}, function() self:on_move_left() end, {builtin = true})
    self:map({"l", "<Right>"}, function() self:on_move_right() end, {builtin = true})

    if not private[self].showaccept and private[self].fullrow then
        self:map("<CR>", function() self:_do_accept() end, {builtin = true})
    end
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

    if vim.is_callable(private[self].added) then
        newrow = private[self].added(self, newrow, {
            row = private[self].rowindex,
            col = private[self].colindex
        }) or { }
    end

    assert(vim.tbl_islist(newrow))
    table.insert(private[self].data, 1, newrow)
    self:update()
end

function TablePopup:_do_accept()
    if private[self].selectionrequired then
        if private[self].rowindex < 0 then
            return
        end

        if not private[self].fullrow and private[self].colindex < 0 then
            return
        end
    end

    self:accept()
end

function TablePopup:on_accept()
    if vim.is_callable(private[self].changed) then
        private[self].changed(self, private[self].data)
    end
end

function TablePopup:on_remove()
    if not private[self].editable then
        return
    end

    if not vim.tbl_isempty(private[self].data) then
        local canremove = true

        if vim.is_callable(private[self].removed) then
            canremove = private[self].removed(self, self:get_current_item(), self.index) ~= false
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

function TablePopup:update()
    if vim.tbl_isempty(private[self].header) then
        error("TablePopup: Header is empty")
    end

    local startcol, w = 0, math.ceil(self.width / #private[self].header)
    self:set_cursor(private[self].rowindex + 2, private[self].colindex * w)

    local t, header = { }, vim.tbl_map(function(h)
        local c = Components.Label(h.label or h.name, {
            col = startcol,
            width = w,
            foreground = "cursor",
            background = "cursor",
            align = vim.F.if_nil(h.align, "center"),
        })

        startcol = startcol + w
        return c
    end, private[self].header)

    for rowidx, rowdata in ipairs(private[self].data) do
        local row = { }
        startcol = 0

        for colidx, h in pairs(private[self].header) do
            if h.name then
                local v, c = rowdata[h.name], nil

                local celldata = {
                    value = v,
                    header = h,
                    row = rowdata,
                    label = h.label or h.name or "",

                    options = {
                        col = startcol,
                        width = w,
                        showlabel = false,
                        showicon = false,
                        align = vim.F.if_nil(h.align, "center"),
                        flat = true,
                    },

                    do_update = function(value)
                        if private[self].editable then
                            rowdata[h.name] = value

                            if vim.is_callable(private[self].cellchanged) then
                                private[self].cellchanged(self, {
                                    header = h,
                                    rowdata = rowdata,
                                    data = private[self].data,
                                    index = rowidx,
                                })
                            end

                            self:update()
                        end
                    end
                }

                if type(h.options) == "table" then
                    celldata.options = vim.tbl_extend("keep", celldata.options, h.options)
                end

                if type(h.type) == "table" and h.type:instanceof(Cells.Cell) then
                    c = h.type(celldata):create()
                elseif vim.is_callable(h.type) then
                    c = h.type(celldata)
                end

                if not c then
                    c = Cells.LabelCell(celldata):create()
                end

                assert(c:instanceof(Base.Component))

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

    local needsactions = vim.tbl_islist(private[self].actions) and not vim.tbl_isempty(private[self].actions)

    if needsactions or private[self].showaccept then
        self:fill_components(t, self.height - 4)

        local buttons = { }

        if needsactions then
            table.insert(buttons, Components.Button(private[self].actiontext, {
                key = "z",
                col = 1,

                event = function()
                    vim.ui.select(private[self].actions, {
                        prompt = "Actions"
                    }, function(choice, idx)
                        if choice and vim.is_callable(private[self].actionselected) then
                            private[self].actionselected(choice, idx)
                        end
                    end)
                end,
            }))
        end

        if private[self].showaccept then
            table.insert(buttons, Components.Button(private[self].accepttext, {
                key = "A",
                col = -2,
                event = function() self:_do_accept() end
            }))
        end

        table.insert(t, buttons)
    end

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
        self:update()

        if vim.is_callable(private[self].selected) then
            private[self].selected(self, self:get_current_row(), self:get_current_col())
        end
    end
end

return TablePopup
