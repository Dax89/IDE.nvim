local Utils = require("ide.utils")

local Buffer = Utils.class()

function Buffer:init(options)
    self.options = options or { }
    self.hbuf = vim.api.nvim_create_buf(false, true)
    self.hns = vim.api.nvim_create_namespace("canvas_" .. tostring(self.hbuf))
    self.hgrp = vim.api.nvim_create_augroup("canvas_agroup_" .. tostring(self.hbuf), {})

    self.data = { }
    self._keys = { }

    vim.api.nvim_buf_set_option(self.hbuf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(self.hbuf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(self.hbuf, "textwidth", self:get_width())

    if self.options.name then
        vim.api.nvim_buf_set_option(self.hbuf, "filetype", self.options.name)
    end
end

function Buffer:map(key, v, options)
    options = options or { }
    table.insert(self._keys, {key = key, builtin = options.builtin})
    options.builtin = nil

    vim.keymap.set("n", key, v, vim.tbl_extend("force", options, {
        nowait = true,
        buffer = self.hbuf
    }))
end

function Buffer:refresh()
    self:clear()
    self:render()
end

function Buffer:clear()
    self.data = self:_blank()
end

function Buffer:_calc_coord(p, v)
    if type(p) == "number" then
        return p
    end

    if vim.endswith(p, "%") then
        return math.floor((v * tonumber(p:sub(0, -2))) / 100)
    end

    error("Unsupported coordinate: '" .. p .. "'")
end

function Buffer:calc_col(c)
    local v, w = c.col, self:calc_width(c)

    if type(v) == "number" and v < 0 then
        v = self:get_width() + v - w + 1
    end

    return self:_calc_coord(v, self:get_width())
end

function Buffer:calc_row(c)
    local v, h = c.row, self:calc_height(c)

    if type(v) == "number" and v < 0 then
        v = self:get_height() - h + 1
    end

    return self:_calc_coord(v, self:get_height())
end

function Buffer:calc_width(c)
    return self:_calc_coord(c.width, self:get_width())
end

function Buffer:calc_height(c)
    return self:_calc_coord(c.height, self:get_height())
end

function Buffer:_destroy()
    if self.hbuf then
        self:unmap_all(true)
        vim.api.nvim_buf_delete(self.hbuf, {force = true})
        self.hbuf = nil
    end
end

function Buffer:get_theme()
    return require("ide.ui.theme")
end

function Buffer:unmap_all(builtins)
    for _, k in ipairs(self._keys) do
        if not k.builtin or (k.builtin and builtins) then
            vim.keymap.del("n", k.key, {buffer = self.hbuf})
        end
    end

    self._keys = { }
end

function Buffer:_blank()
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

function Buffer:get_width()
    return self.options.width
end

function Buffer:get_height()
    return self.options.height
end

function Buffer:render()
end

return Buffer
