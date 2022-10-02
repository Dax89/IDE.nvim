local Utils = require("ide.utils")
local Dialogs = require("ide.ui.dialogs")
local Components = require("ide.ui.components")

local ListPopup = Utils.class(Dialogs.Dialog)

function ListPopup:init(items, title, options)
    self._options = options or { }
    self.items = items or { }
    self.index = 0

    if not self._options.height then
        self._options.height = math.max(math.min(2, #self.items), 10)
    end

    Dialogs.Dialog.init(self, title, {
        height = self._options.height,
        showhelp = false,
        zindex = 50,
    })

    self:_update_items()
    self:map("a", function() self:on_add() end, {builtin = true})
    self:map("d", function() self:on_remove() end, {builtin = true})
    self:map({"j", "<Down>"}, function() self:on_move_down() end, {builtin = true})
    self:map({"k", "<Up>"}, function() self:on_move_up() end, {builtin = true})
    self:map("<CR>", function() self:on_item_selected() end, {builtin = true})
end

function ListPopup:_update_items()
    local i = 0

    self:set_components(vim.tbl_map(function(item)
        local c =  Components.Label(vim.is_callable(self._options.formatitem) and self._options.formatitem(self, item) or item, {
            width = "100%",
            foreground = i == self.index and "selected" or nil,
            background = i == self.index and "selected" or nil,
        })
        i = i + 1
        return c
    end, self.items))

    self:render()
end

function ListPopup:_update_index(index, force)
    local oldindex = self.index

    if index >= #self.items then
        index = #self.items - 1
    elseif index < 0 then
        index = 0
    end

    if force or index ~= oldindex then
        self.index = index
        self:_update_items()
    end
end

function ListPopup:get_current_item()
    return self.items[self.index]
end

function ListPopup:on_move_down()
    if not vim.tbl_isempty(self.items) then
        self:_update_index(self.index + 1)
    end
end

function ListPopup:on_move_up()
    if not vim.tbl_isempty(self.items) then
        self:_update_index(self.index - 1)
    end
end

function ListPopup:on_item_selected()
    if vim.is_callable(self._options.selected) then
        self._options.selected(self, self:get_current_item(), self.index)
    end

    self:accept()
end

function ListPopup:on_add()
    vim.ui.input("Insert item", function(choice)
        if choice then
            local newitem = choice

            if self._options.unique then
                local items = vim.is_callable(self._options.formatitem) and
                              vim.tbl_map(function(x) return self._options.formatitem(self, x) end) or
                              self.items

                if vim.tbl_contains(items, newitem) then
                    return
                end
            end

            if vim.is_callable(self._options.add) then
                newitem = self._options.add(self, newitem, self.index) or choice
            end

            table.insert(self.items, 1, newitem)
            self:_update_items()
        end
    end)
end

function ListPopup:on_remove()
    if not vim.tbl_isempty(self.items) then
        local canremove = true

        if vim.is_callable(self._options.remove) then
            canremove = self._options.remove(self, self:get_current_item(), self.index) ~= false
        end

        if canremove then
            table.remove(self.items, self.index + 1)
            self:_update_index(self.index, true) -- Recalculate index, if needed
        end
    end
end

return ListPopup
