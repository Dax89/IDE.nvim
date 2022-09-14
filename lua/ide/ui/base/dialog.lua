local Utils = require("ide.utils")
local Canvas = require("ide.ui.base.canvas")

local Dialog = Utils.class(Canvas)

function Dialog:init(model, options)
    self._title = nil
    self._model = model
    self.data = { }

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
    Canvas.init(self, options)
    self:_model_to_data()
end

function Dialog:check_required(keys)
    keys = keys or vim.tbl_keys(rawget(self.data, "_data"))

    if vim.tbl_isempty(keys) then
        return false
    end

    for _, k in ipairs(keys) do
        if not vim.startswith(k, "_") and (self.data[k] == nil or self.data[k] == "") then
            return false
        end
    end

    return true
end

function Dialog:set_model(l)
    self._model = l
    self:_model_to_data()
end

function Dialog:set_title(title)
    self._title = title
    self:update()
end

function Dialog:update()
    if not self.hbuf then
        return
    end

    local rows = self:render()

    if self._title then
        table.insert(rows, 1, self:render_component({label = self._title, align = "center"}))
        table.insert(rows, 2, self:render_component({type = "hline"}))
        table.insert(rows, 3, "")
    end

    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", true)
    vim.api.nvim_buf_set_lines(self.hbuf, 0, -1, false, rows)
    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", false)
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

        vim.keymap.set("n", "q", function()
            self:close()
        end, {buffer = self.hbuf})
    end
end

function Dialog:render()
    if not self._model then
        return { }
    end

    local c = { }

    for _, row in ipairs(self._model) do
        if vim.tbl_islist(row) then
            table.insert(c, self:render_columns(row))
        else
            table.insert(c, self:render_component(row))
        end
    end

    return c
end

function Dialog:_handle_key(obj)
    if not obj.id then
        return
    end

    local function _update_data(v)
        if v ~= nil then
            obj.value = v
            self.data[obj.id] = v
        end
    end

    if obj.type == "text" then
        vim.ui.input(obj.label or obj.id, _update_data)
    elseif obj.type == "select" then
        vim.ui.select(obj.items, {
            prompt = obj.label or obj.id
        }, _update_data)
    elseif obj.type == "file" then
        require("ide.ui.picker").select_file(function(f)
            _update_data(tostring(f))
        end)
    elseif obj.type == "folder" then
        require("ide.ui.picker").select_folder(function(f)
            _update_data(tostring(f))
        end)
    else
        vim.F.npcall(obj.event, self, obj)
    end
end

function Dialog:_model_to_data()
    self.data = setmetatable({ _data = { } }, {
        __index = function(t, k)
            return rawget(t, "_data")[k]
        end,
        __newindex = function(t, k, v)
            if rawget(t._data, k) ~= v then
                rawset(t._data, k, v)
                self:update()
            end
        end
    })

    if not self._model then
        return
    end

    local proc = function(obj)
        if obj.id and self.data[obj.id] then
            error("Duplicate key '" .. obj.id .. "'")
        end

        if obj.key then
            vim.keymap.set("n", obj.key, function()
                self:_handle_key(obj)
            end, { buffer = self.hbuf})
        end

        if obj.id then
            self.data[obj.id] = obj.value
        end
    end

    for _, row in ipairs(self._model) do
        if vim.tbl_islist(row) then
            for _, col in ipairs(row) do
                proc(col)
            end
        else
            proc(row)
        end
    end
end

return Dialog
