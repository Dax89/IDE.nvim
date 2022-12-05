local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")

local private = Utils.private_stash()
local ListPopup = Utils.class(Dialogs.Dialog)

function ListPopup:init(items, title, options)
    options = options or { }

    private[self] = {
        formatitem = options.formatitem,
        selected = options.selected,
        change = options.change,
        remove = options.remove,
        add = options.add,
        items = vim.F.if_nil(items, { }),
        unique = vim.F.if_nil(options.unique, false),
        editable = vim.F.if_nil(options.editable, true),
    }

    self.index = -1
    self.width = options.width
    self.height = vim.F.if_nil(options.height, math.max(math.min(2, #private[self].items), 12))

    Dialogs.Dialog.init(self, title, {
        zindex = 50,
    })

    self:_update_items()
    self:map("a", function() self:on_add() end, {builtin = true})
    self:map("d", function() self:on_remove() end, {builtin = true})
    self:map("<CR>", function() self:on_edit() end, {builtin = true})
    self:map({"j", "<Down>"}, function() self:on_move_down() end, {builtin = true})
    self:map({"k", "<Up>"}, function() self:on_move_up() end, {builtin = true})
end

function ListPopup:_update_items()
    local i = 0

    local t = vim.tbl_map(function(item)
        local c =  Components.Label(vim.is_callable(private[self].formatitem) and private[self].formatitem(self, item) or item, {
            width = "100%",
            foreground = i == self.index and "selected" or nil,
            background = i == self.index and "selected" or nil,
        })
        i = i + 1
        return c
    end, private[self].items)

    self:fill_components(t, self.height - 4)

    table.insert(t, Components.Button("Accept", {
        key = "A",
        col = -2,
        click = function() self:accept() end
    }))

    self:set_components(t)
    self:render()
end

function ListPopup:_update_index(index, force)
    local oldindex = self.index

    if index >= #private[self].items then
        index = #private[self].items - 1
    elseif index < 0 then
        index = 0
    end

    if force or index ~= oldindex then
        self.index = index
        self:_update_items()

        if vim.is_callable(private[self].selected) then
            private[self].selected(self, self:get_current_item())
        end
    end
end

function ListPopup:get_current_item()
    return private[self].items[self.index]
end

function ListPopup:on_move_down()
    if not vim.tbl_isempty(private[self].items) then
        self:_update_index(self.index + 1)
    end
end

function ListPopup:on_move_up()
    if not vim.tbl_isempty(private[self].items) then
        self:_update_index(self.index - 1)
    end
end

function ListPopup:on_item_selected()
    if vim.is_callable(private[self].selected) then
        private[self].selected(self, self:get_current_item(), self.index)
    end

    self:accept()
end

function ListPopup:_item_exists(item)
    local items = vim.is_callable(private[self].formatitem) and
                  vim.tbl_map(function(x) return private[self].formatitem(self, x) end) or
                  private[self].items

    return vim.tbl_contains(items, item)
end

function ListPopup:on_add()
    if not private[self].editable then
        return
    end

    vim.ui.input({
        prompt = "Insert item"
    }, function(choice)
        if choice then
            if private[self].unique and self:_item_exists(choice) then
                return
            end

            local newitem = choice

            if vim.is_callable(private[self].add) then
                newitem = private[self].add(self, newitem, self.index) or choice
            end

            table.insert(private[self].items, 1, newitem)
            self:_update_items()
        end
    end)
end

function ListPopup:on_remove()
    if not private[self].editable then
        return
    end

    if not vim.tbl_isempty(private[self].items) then
        local canremove = true

        if vim.is_callable(private[self].remove) then
            canremove = private[self].remove(self, self:get_current_item(), self.index) ~= false
        end

        if canremove then
            table.remove(private[self].items, self.index + 1)
            self:_update_index(self.index, true) -- Recalculate index, if needed
        end
    end
end

function ListPopup:on_edit()
    if not private[self].editable then
        return
    end

    vim.ui.input({
        prompt = "Edit item",
        default = private[self].items[self.index + 1]
    }, function(choice)
        if choice then
            if private[self].unique and self:_item_exists(choice) then
                return
            end

            local newitem = choice

            if vim.is_callable(private[self].add) then
                newitem = private[self].add(self, newitem, self.index) or choice
            end

            private[self].items[self.index + 1] = newitem
            self:_update_items()
        end
    end)
end

function ListPopup:on_accept()
    if vim.is_callable(private[self].change) then
        private[self].change(self, private[self].items)
    end
end

return ListPopup
