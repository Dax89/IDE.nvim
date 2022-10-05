local Utils = require("ide.utils")
local Buffer = require("ide.ui.base.buffer")

local private = Utils.private_stash()
local Window = Utils.class(Buffer)

function Window:init(options)
    options = options or { }

    private[self] = {
        style = vim.F.if_nil(options.style, "minimal"),
        relative = vim.F.if_nil(options.relative, "editor"),
        border = vim.F.if_nil(options.border, "single"),
        showhelp = vim.F.if_nil(options.showhelp, true),
    }

    self.hwin = nil
    self.width = vim.F.if_nil(self.width, vim.F.if_nil(options.width, math.ceil(vim.o.columns * 0.75)))
    self.height = vim.F.if_nil(self.height, options.height)
    Buffer.init(self, {name = private[self].name})
end

function Window:has_show_help()
    return private[self].showhelp
end

function Window:show()
    if not self.hwin then
        private[self].row = (vim.o.lines - self.height) / 2
        private[self].col = (vim.o.columns - self.width) / 2

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

