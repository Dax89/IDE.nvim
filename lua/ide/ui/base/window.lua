local Utils = require("ide.utils")
local Buffer = require("ide.ui.base.buffer")

local Window = Utils.class(Buffer)

function Window:init(options)
    self.winoptions = vim.tbl_extend("force", {
        style = "minimal",
        relative = "editor",
        width = math.ceil(vim.o.columns * 0.75),
        border = "single",
    }, options or { })

    self.hwin = nil

    Buffer.init(self, {
        width = self.winoptions.width,
        height = self.winoptions.height,
        name = self.winoptions.name
    })
end

function Window:show()
    if not self.hwin then
        self.winoptions.row = (vim.o.lines - self.winoptions.height) / 2
        self.winoptions.col = (vim.o.columns - self.winoptions.width) / 2

        self.hwin = vim.api.nvim_open_win(self.hbuf, true, {
            border = self.winoptions.border,
            style = self.winoptions.style,
            relative = self.winoptions.relative,
            row = self.winoptions.row,
            col = self.winoptions.col,
            width = self.winoptions.width,
            height = self.winoptions.height,
            zindex = self.winoptions.zindex,
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

