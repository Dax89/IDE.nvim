local Utils = require("ide.utils")
local Canvas = require("ide.ui.lib.base.canvas")

local Dialog = Utils.class(Canvas)

function Dialog:init(options)
    self.hwin = nil

    options = vim.tbl_extend("force", {
        style = "minimal",
        relative = "editor",
        width = math.ceil(vim.o.columns * 0.75),
        height = math.ceil(vim.o.lines * 0.75),
        border = "single",
    }, options or { })

    options.row = (vim.o.lines - options.height) / 2
    options.col = (vim.o.columns - options.width) / 2

    Canvas.init(self, options)
end

function Dialog:show()
    if not self.hwin then
        self.hwin = vim.api.nvim_open_win(self.hbuf, true, self.options)
        vim.api.nvim_win_set_option(self.hwin, "sidescrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "scrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "wrap", false)
        vim.api.nvim_win_set_hl_ns(self.hwin, self.hns)
    end

    self:refresh()
end

function Dialog:close()
    self:_destroy()

    if self.hwin then
        if vim.api.nvim_win_is_valid(self.hwin) then
            vim.api.nvim_win_close(self.hwin, true)
        end

        self.hwin = nil
    end
end

function Dialog:on_escape()
    self:close()
end

return Dialog
