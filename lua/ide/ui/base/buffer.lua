local Utils = require("ide.utils")

local private = Utils.private_stash()
local Buffer = Utils.class()

function Buffer:init(options)
    options = options or { }

    self.width = vim.F.if_nil(self.width, vim.F.if_nil(options.width, 0))
    self.height = vim.F.if_nil(self.height, vim.F.if_nil(options.height, 0))
    self.hbuf = vim.api.nvim_create_buf(false, true)
    self.hns = vim.api.nvim_create_namespace("nvide_buffer_" .. tostring(self.hbuf))
    self.hgrp = vim.api.nvim_create_augroup("nvide_buffer_agroup_" .. tostring(self.hbuf), {})

    private[self] = {
        name = options.name,
        keys = { },
    }

    self.data = { }

    vim.api.nvim_buf_set_option(self.hbuf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(self.hbuf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(self.hbuf, "textwidth", self.width)

    if private[self].name then
        vim.api.nvim_buf_set_option(self.hbuf, "filetype", private[self].name)
    end
end

function Buffer:map(keys, v, options)
    options = options or { }
    local builtin = options.builtin
    options.builtin = nil

    if not vim.tbl_islist(keys) then
        keys = {keys}
    end

    for _, k in ipairs(keys) do
        table.insert(private[self].keys, {key = k, builtin = builtin})

        vim.keymap.set("n", k, v, vim.tbl_extend("force", options, {
            nowait = true,
            buffer = self.hbuf
        }))
    end
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
        v = self.width + v - w + 1
    end

    return self:_calc_coord(v, self.width)
end

function Buffer:calc_row(c)
    local v, h = c.row, self:calc_height(c)

    if type(v) == "number" and v < 0 then
        v = self.height - h + 1
    end

    return self:_calc_coord(v, self.height)
end

function Buffer:calc_width(c)
    return self:_calc_coord(c.width, self.width)
end

function Buffer:calc_height(c)
    return self:_calc_coord(c.height, self.height)
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
    for _, k in ipairs(private[self].keys) do
        if not k.builtin or (k.builtin and builtins) then
            vim.keymap.del("n", k.key, {buffer = self.hbuf})
        end
    end

    private[self].keys = { }
end

function Buffer:_blank()
    local data = { }

    for _=1, self.height do
        local row = { }

        for _=1, self.width do
            table.insert(row, " ")
        end

        table.insert(data, row)
    end

    return data
end

function Buffer:commit(cb)
    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", true)
    vim.api.nvim_buf_clear_namespace(self.hbuf, self.hns, 0, -1)
    cb()
    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", false)
end

function Buffer:render()
end

return Buffer
