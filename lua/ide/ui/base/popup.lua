local Utils = require("ide.utils")
local Model = require("ide.ui.base.model")

local Popup = Utils.class(Model)

function Popup:init(options)
    self.hwin = nil

    options = vim.tbl_extend("force", {
        style = "minimal",
        relative = "editor",
        width = math.ceil(vim.o.columns * 0.75),
        border = "single",
    }, options or { })

    Model.init(self, options)
end

function Popup:set_components(components)
    if not self.options.height then
        self.options.height = not vim.tbl_isempty(components) and #components or math.ceil(vim.o.lines * 0.75)
    end

    Model.set_components(self, components)
end

function Popup:show()
    if not self.hwin then

        if vim.tbl_isempty(self._components) then
            self:set_components({})
        end

        self.options.row = (vim.o.lines - self.options.height) / 2
        self.options.col = (vim.o.columns - self.options.width) / 2

        self.hwin = vim.api.nvim_open_win(self.hbuf, true, {
            border = self.options.border,
            style = self.options.style,
            relative = self.options.relative,
            row = self.options.row,
            col = self.options.col,
            width = self.options.width,
            height = self.options.height,
        })

        vim.api.nvim_win_set_option(self.hwin, "sidescrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "scrolloff", 0)
        vim.api.nvim_win_set_option(self.hwin, "wrap", false)
        vim.api.nvim_win_set_hl_ns(self.hwin, self.hns)
    end

    self:refresh()
end

function Popup:close()
    self:_destroy()

    if self.hwin then
        if vim.api.nvim_win_is_valid(self.hwin) then
            vim.api.nvim_win_close(self.hwin, true)
        end

        self.hwin = nil
    end
end

return Popup

