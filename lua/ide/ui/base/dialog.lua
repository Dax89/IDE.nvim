local Utils = require("ide.utils")
local Canvas = require("ide.ui.base.canvas")

local Dialog = Utils.class(Canvas)

function Dialog:init(model, options)
    self._title = nil

    options = vim.tbl_extend("force", {
        style = "minimal",
        relative = "editor",
        width = math.ceil(vim.o.columns * 0.75),
        height = math.ceil(vim.o.lines * 0.75),
        border = "single"
    }, options or { })

    options.row = (vim.o.lines - options.height) / 2
    options.col = (vim.o.columns - options.width) / 2

    self.hwin = nil
    Canvas.init(self, model, options)
end

function Dialog:set_title(title)
    self._title = title
    self:update()
end

function Dialog:close()
    if self.hwin then
        vim.api.nvim_win_close(self.hwin, true)
    end

    self:_close_buffer()
end

function Dialog:show()
    self:update()

    if not self.hwin then
        self.hwin = vim.api.nvim_open_win(self.hbuf, true, self.options)
        vim.api.nvim_win_set_hl_ns(self.hwin, self.hns)

        vim.keymap.set("n", "<ESC>", function()
            self:close()
        end, {buffer = self.hbuf})
    end
end

function Dialog:on_render(rows)
    if self._title then
        table.insert(rows, 1, self:render_line({label = self._title, align = "center", foreground = "Title"}))
        table.insert(rows, 2, self:render_line({type = "hline"}))
    end
end

return Dialog
