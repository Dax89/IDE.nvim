local Utils = require("ide.utils")
local Canvas = require("ide.ui.base.canvas")

local Model = Utils.class(Canvas)

function Model:init(options)
    self._extmarks = { }
    self._components = { }
    self.model = self:_reset_model()

    self:_create_mapping()
    Canvas.init(self, options)
end

function Model:_reset_model()
    return setmetatable({
        _data = { },
        _components = { },
        add_component = function(m, c)
            m._components[c.id] = c
        end,
        get_component = function(m, id)
            return m._components[id]
        end,
        get_data = function(m)
            return m._data
        end
    }, {
        __index = function(t, k)
            return rawget(t, "_data")[k]
        end,
        __newindex = function(t, k, v)
            local oldv = rawget(t._data, k)
            if oldv ~= v then
                rawset(t._data, k, v)

                local c = t:get_component(k)

                if c then
                    c:set_value(v)
                end

                self:on_model_changed(t, k, v, oldv)
                self:render()
            end
        end
    })
end

function Model:validate_model(keys)
    keys = keys or vim.tbl_keys(rawget(self.model, "_data"))

    if vim.tbl_isempty(keys) then
        return false
    end

    for _, k in ipairs(keys) do
        local c = self.model:get_component(k)
        if c.optional ~= true and (self.model[k] == nil or self.model[k] == "") then
            return false
        end
    end

    return true
end

function Model:on_help()
    if not vim.tbl_isempty(self._extmarks) then
        for _, id in ipairs(self._extmarks) do
            vim.api.nvim_buf_del_extmark(self.hbuf, self.hns, id)
        end

        self._extmarks = { }
        return
    end

    for _, c in ipairs(self._components) do
        if c.key then
            local row, col = self:calc_row(c), self:calc_col(c)

            table.insert(self._extmarks, vim.api.nvim_buf_set_extmark(self.hbuf, self.hns, row, col, {
                virt_text = {{c.key, "ErrorMsg"}},
                virt_text_pos = "overlay"
            }))
        end
    end
end

function Model:on_escape()
end

function Model:on_event()
end

function Model:on_click()
end

function Model:on_doubleclick()
end

function Model:_create_mapping()
    local function _send(t)
        local cursor = vim.api.nvim_win_get_cursor(self.hwin)
        self:event_at(t, cursor[1], cursor[2])
    end

    self:map("<C-h>", function()
        if self.options.showhelp ~= false then
            self:on_help()
        end
    end)

    self:map("<ESC>", function()
        _send("escape")
    end)

    self:map("<CR>", function()
        _send("event")
    end)

    self:map("<LeftRelease>", function()
        if self._dblclick then
            self._dblclick = false
        else
            _send("click")
        end
    end)

    self:map("<2-LeftMouse>", function()
        self._dblclick = true
        _send("doubleclick")
    end)
end

function Model:_unmap_all()
    for _, c in ipairs(self._components) do
        if c.key then
            vim.keymaps.del("n", c.key, {
                buffer = self.hbuf
            })
        end
    end
end

function Model:_find_component(row, col)
    row = row - 1
    col = col - 1

    for _, crow in ipairs(self._components) do
        local cl = vim.tbl_islist(crow) and crow or {crow}

        for _, c in ipairs(cl) do
            local srow, scol = self:calc_row(c), self:calc_col(c)
            local erow, ecol = srow + self:calc_height(c), scol + self:calc_width(c)

            if (row >= srow and row < erow) and (col >= scol and col < ecol) then
                return c
            end
        end
    end

    return nil
end

function Model:event_at(type, row, col)
    local c = self:_find_component(row, col)

    if c then
        self:event(c, type, row, col)
    else
        self["on_" .. type](self)
    end
end

function Model:event(c, type, row, col)
    self["on_" .. type](self)

    if not row or not col then
        local cursor = vim.api.nvim_win_get_cursor(self.hwin)
        row, col = cursor[1], cursor[1]
    end

    local e = {
        sender = self,
        row = row,
        col = col,

        update = function()
            if c.id then
                self.model[c.id] = c:get_value()
            end
        end
    }

    if vim.is_callable(c["on_" .. type]) then
        c["on_" .. type](c, e)
    end
end

function Model:get_component(id)
    return self.model:get_component(id)
end

function Model:set_components(components)
    local RESERVED_KEYS = {
        ["<2-LeftMouse>"] = true,
        ["<LeftRelease>"] = true,
        ["<ESC>"] = true,
        ["<CR>"] = true,
        ["<C-h>"] = true
    }

    self._extmarks = { }
    self._components = { }
    self.model = self:_reset_model()
    self:clear()
    self:_unmap_all()

    for i, row in ipairs(components) do
        local cl = vim.tbl_islist(row) and row or {row}

        for _, c in ipairs(cl) do
            c.row = i - 1
            table.insert(self._components, c)

            if c.id then
                if self.model:get_component(c.id) then
                    error("Duplicate id '" .. c.id .. "'")
                end

                self.model:add_component(c)
                self.model[c.id] = c:get_value()

                if c.key then
                    if RESERVED_KEYS[c.key] then
                        error("Key '" .. c.key .. "' is reserved")
                    end

                    self:map(c.key, function() self:event(c, "event") end)
                end
            end
        end
    end
end

function Model:render()
    local Theme = require("ide.ui.theme")

    local function hl(h, t)
        if not h then
            return nil
        end

        if vim.startswith(h, "#") then
            return h
        end

        if type(t) ~= "table" then
            t = {t}
        end

        h = Theme.get_color(h)
        local hln = vim.api.nvim_get_hl_by_name(h, true)

        for _, ct in ipairs(t) do
            if hln[ct] then
                return "#" .. bit.tohex(hln[ct], 6)
            end
        end
        error("Cannot find color '" .. h .. "'")
    end

    local UTF8 = require("ide.ui.utils.utf8")

    for _, c in ipairs(self._components) do
        local d = c:render(self)

        if d then
            local rowidx = self:calc_row(c) + 1
            local row = self.data[rowidx]

            if row then
                local i, len = 0, UTF8.len(d)

                for col = self:calc_col(c), #row - 1 do
                    row[col + 1] = i < len and UTF8.char(d, i) or " "
                    i = i + 1
                end
            end
        end
    end

    local lines = { }

    for _, row in ipairs(self.data) do
        table.insert(lines, table.concat(row))
    end

    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", true)
    vim.api.nvim_buf_clear_namespace(self.hbuf, self.hns, 0, -1)
    vim.api.nvim_buf_set_lines(self.hbuf, 0, -1, false, lines)

    for i, c in ipairs(self._components) do
        if c.foreground or c.background or c.bold then
            local n = ("highlight_nvide_%d"):format(i)

            vim.api.nvim_set_hl(self.hns, n, {
                foreground = hl(c.foreground, {"foreground", "background"}),
                background = hl(c.background, {"background", "foreground"}),
                bold = c.bold or false
            })

            local start = self:calc_col(c)

            for r = 0, self:calc_height(c) - 1 do
                vim.api.nvim_buf_add_highlight(self.hbuf, self.hns, n, c.row + r, start, start + self:calc_width(c))
            end
        end
    end

    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", false)
end

function Model:on_model_changed(model, k, newvalue, oldvalue)
end

return Model

