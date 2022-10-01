local Utils = require("ide.utils")

local Canvas = Utils.class()

function Canvas:init(options)
    self.options = options or { }
    self.hbuf = vim.api.nvim_create_buf(false, true)
    self.hns = vim.api.nvim_create_namespace("canvas_" .. tostring(self.hbuf))
    self.hgrp = vim.api.nvim_create_augroup("canvas_agroup_" .. tostring(self.hbuf), {})

    self._dblclick = false
    self.data = { }
    self.model = self:_reset_model()

    vim.api.nvim_buf_set_option(self.hbuf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(self.hbuf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(self.hbuf, "textwidth", self:get_width())

    if self.options.name then
        vim.api.nvim_buf_set_option(self.hbuf, "filetype", self.options.name)
    end
end

function Canvas:map(key, v, options)
    vim.keymap.set("n", key, v, vim.tbl_extend("force", options or { }, {
        nowait = true,
        buffer = self.hbuf
    }))
end

function Canvas:refresh()
    self:clear()
    self:render()
end

function Canvas:clear()
    self.data = self:_blank()
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

return Canvas
