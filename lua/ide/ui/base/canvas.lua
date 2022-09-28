local Utils = require("ide.utils")

local Canvas = Utils.class()

function Canvas:init(options)
    self.options = options or { }
    self.hbuf = vim.api.nvim_create_buf(false, true)
    self.hns = vim.api.nvim_create_namespace("canvas_" .. tostring(self.hbuf))
    self.hgrp = vim.api.nvim_create_augroup("canvas_agroup_" .. tostring(self.hbuf), {})

    self._dblclick = false
    self._extmarks = { }
    self._components = { }
    self._data = { }
    self.model = self:_reset_model()

    vim.api.nvim_buf_set_option(self.hbuf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(self.hbuf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(self.hbuf, "textwidth", self:get_width())

    if self.options.name then
        vim.api.nvim_buf_set_option(self.hbuf, "filetype", self.options.name)
    end

    self:_create_mapping()
end

function Canvas:_reset_model()
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
                t:get_component(k):set_value(v)
                self:on_model_changed(t, k, v, oldv)
                self:render()
            end
        end
    })
end

function Canvas:validate_model(keys)
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

function Canvas:on_help()
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

function Canvas:on_escape()
end

function Canvas:on_event()
end

function Canvas:on_click()
end

function Canvas:on_doubleclick()
end

function Canvas:_create_mapping()
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

function Canvas:map(key, v, options)
    vim.keymap.set("n", key, v, vim.tbl_extend("force", options or { }, {
        nowait = true,
        buffer = self.hbuf
    }))
end

function Canvas:_unmap_all()
    for _, c in ipairs(self._components) do
        if c.key then
            vim.keymaps.del("n", c.key, {
                buffer = self.hbuf
            })
        end
    end
end

function Canvas:_find_component(row, col)
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

function Canvas:event_at(type, row, col)
    local c = self:_find_component(row, col)

    if c then
        self:event(c, type, row, col)
    else
        self["on_" .. type](self)
    end
end

function Canvas:event(c, type, row, col)
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

function Canvas:get_component(id)
    return self.model:get_component(id)
end

function Canvas:set_components(components)
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
                if self.model[c.id] then
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

function Canvas:refresh()
    self:clear()
    self:render()
end

function Canvas:clear()
    self._data = self:_blank()
end

function Canvas:_distribute(s, w)
    local UTF8 = require("ide.ui.utils.utf8")
    local l = UTF8.len(s)
    return l < w and (s .. (" "):rep(w - l)) or s:sub(0, vim.str_byteindex(s, w))
end

function Canvas:_calc_coord(p, v)
    if type(p) == "number" then
        return p
    end

    if vim.endswith(p, "%") then
        return math.floor((v * tonumber(p:sub(0, -2))) / 100)
    end

    error("Unsupported coordinate: '" .. p .. "'")
end

function Canvas:calc_col(c)
    local v, w = c.col, self:calc_width(c)

    if type(v) == "number" and v < 0 then
        v = self:get_width() + v - w + 1
    end

    return self:_calc_coord(v, self:get_width())
end

function Canvas:calc_row(c)
    local v, h = c.row, self:calc_height(c)

    if type(v) == "number" and v < 0 then
        v = self:get_height() - h + 1
    end

    return self:_calc_coord(v, self:get_height())
end

function Canvas:calc_width(c)
    return self:_calc_coord(c.width, self:get_width())
end

function Canvas:calc_height(c)
    return self:_calc_coord(c.height, self:get_height())
end

function Canvas:render()
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
            local row = self._data[rowidx]

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

    for _, row in ipairs(self._data) do
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

function Canvas:_destroy()
    if self.hbuf then
        vim.api.nvim_buf_delete(self.hbuf, {force = true})
        self.hbuf = nil
    end
end

function Canvas:_blank()
    local data = { }

    for _=1, self:get_height() do
        local row = { }

        for _=1, self:get_width() do
            table.insert(row, " ")
        end

        table.insert(data, row)
    end

    return data
end

function Canvas:get_width()
    return self.options.width
end

function Canvas:get_height()
    return self.options.height
end

function Canvas:on_model_changed(model, k, newvalue, oldvalue)
end

return Canvas
