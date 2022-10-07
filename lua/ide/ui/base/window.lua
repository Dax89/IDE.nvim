local Utils = require("ide.utils")
local Buffer = require("ide.ui.base.buffer")
local Screen = require("ide.ui.utils.screen")

local private = Utils.private_stash()
local Window = Utils.class(Buffer)

function Window:init(options)
    options = options or { }

    private[self] = {
        style = vim.F.if_nil(options.style, "minimal"),
        relative = vim.F.if_nil(options.relative, "editor"),
        border = vim.F.if_nil(options.border, "single"),
    }

    self.hwin = nil
    self.width = vim.F.if_nil(self.width, vim.F.if_nil(options.width, Screen.get_width("75%")))
    self.height = vim.F.if_nil(self.height, options.height)
    Buffer.init(self, {name = private[self].name})
end

function Window:get_cursor()
    if self.hwin ~= nil then
        return vim.api.nvim_win_get_cursor(self.hwin)
    end

    return {1, 1}
end

function Window:set_cursor(row, col)
    if type(row) == "table" then
        col = row[2]
        row = row[1]
    end

    if self.hwin ~= nil then
        local cc = self:get_cursor()
        row = math.max(vim.F.if_nil(row, cc[1]), 1)
        col = math.max(vim.F.if_nil(col, cc[2]), 0)
        vim.api.nvim_win_set_cursor(self.hwin, {row, col})
    end
end

function Window:show()
    if not self.hwin then
        private[self].row = (Screen.get_height() - self.height) / 2
        private[self].col = (Screen.get_width() - self.width) / 2

        self.hwin = vim.api.nvim_open_win(self.hbuf, true, {
            border = private[self].border,
            style = private[self].style,
            relative = private[self].relative,
            row = private[self].row,
            col = private[self].col,
            zindex = private[self].zindex,
            width = self.width,
            height = self.height,
        })

        vim.api.nvim_win_set_option(self.hwin, "sidescrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "scrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "wrap", false)
        vim.api.nvim_win_set_hl_ns(self.hwin, self.hns)
    end

    self:refresh()
end

function Window:close()
    self:_destroy()

    if self.hwin then
        if vim.api.nvim_win_is_valid(self.hwin) then
            vim.api.nvim_win_close(self.hwin, true)
        end

        self.hwin = nil
    end
end

return Window

