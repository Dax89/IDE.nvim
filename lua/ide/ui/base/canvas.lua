local Utils = require("ide.utils")

local Canvas = Utils.class()

function Canvas:init(model, options)
    self._model = model
    self.options = options
    self.data = { }

    self.hbuf = vim.api.nvim_create_buf(false, true)
    self.hns = vim.api.nvim_create_namespace(("namespace_%d"):format(self.hbuf))
    vim.api.nvim_buf_set_option(self.hbuf, "filetype", "ide-ui")
end

function Canvas:set_model(l)
    self._model = l
    self:_model_to_data()
end

function Canvas:get_width()
    return self.options.width
end

function Canvas:get_height()
    return self.options.height
end

function Canvas:check_required(keys)
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

function Canvas:_close_buffer()
    if self.hbuf then
        vim.api.nvim_buf_delete(self.hbuf, {force = true})
    end
end

function Canvas:_model_to_data()
    self.data = setmetatable({ _data = { }, _layout = { } }, {
        __index = function(t, k)
            return rawget(t, "_data")[k]
        end,
        __newindex = function(t, k, v)
            local oldv = rawget(t._data, k)
            if oldv ~= v then
                rawset(t._data, k, v)
                rawget(t, "_layout")[k].value = v
                self:on_data_changed(t, k, v, oldv)
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
            self.data._layout[obj.id] = obj
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

function Canvas:_handle_key(obj)
    if not obj.id then
        return
    end

    local function _update_data(v)
        if v ~= nil then
            self.data[obj.id] = v
        end
    end

    if obj.type == "text" then
        vim.ui.input(obj.label or obj.id, _update_data)
    elseif obj.type == "select" then
        local items = vim.is_callable(obj.items) and obj.items(self, obj) or obj.items

        if not vim.tbl_isempty(items) then
            vim.ui.select(items, {
                prompt = obj.label or obj.id
            }, _update_data)
        end
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

function Canvas:_apply_style(c)
    if c.type == "button" then
        return {foreground = "Operator"}
    end

    return {foreground = "Keyword"}
end

function Canvas:render_line(components)
    if not vim.tbl_islist(components) then
        components = {components}
    end

    local line, col, colw, totcol = { }, "", self:get_width() / #components, 0

    local function chunk(s, style)
        if not s then
            return
        end

        if style then
            if not self._state.highlights[self._state.line] then
                self._state.highlights[self._state.line] = { }
            end

            table.insert(self._state.highlights[self._state.line], vim.tbl_extend("force", style, {
                colstart = totcol,
                colend = totcol + #s,
            }))
        end

        totcol = totcol + #s
        col = col .. s
    end

    local function trunc(s, w)
        if #s > w then
            s = s:sub(0, w - 3) .. "..."
        end

        return s
    end

    local function fill(w)
        if w > 0 then
            col = col .. (" "):rep(w)
            totcol = totcol + w
        end
    end

    local function getw()
        return colw - #col
    end

    local function default(c)
        local nkey = c.key and #c.key + 1 or 0
        local style = vim.tbl_extend("force", self:_apply_style(c), c)

        if c.label then
            if c.align == "right" then
                fill(getw() - #c.label - nkey)
                chunk(c.label, style)
            elseif c.align == "center" then
                local w = math.max(math.ceil((getw() - #c.label)), 0) / 2
                fill(w)
                chunk(c.label, style)
                fill(w)
            else
                chunk(c.label .. " ", style)
            end
        end

        if c.value then
            chunk(trunc(c.value, getw() - nkey))
        end

        if not c.align or c.align == "left" then
            fill(getw() - nkey)
        end

        if c.key then
            chunk(" " .. c.key, {foreground = "Constant", background = style.background})
        else
            fill(getw())
        end
    end

    for i, c in ipairs(components) do
        if #components > 1 then -- Add a 1 cell gap between columns
            if i < #components then
                colw = colw - 1
            else
                colw = colw + #components - 1
            end
        end

        if c.type == "hline" then
            chunk(string.rep("⎯", colw))
        else
            default(c)
        end

        if #components > 1 and i < #components then -- Add the gap
            chunk(" ")
        end

        table.insert(line, col)
        col = ""
    end

    return table.concat(line)
end

function Canvas:_render()
    if not self._model then
        return { }
    end

    local c = { }

    for line, components in ipairs(self._model) do
        local bufferline = self._state.linebase + line
        self._state.line = bufferline
        table.insert(c, self:render_line(components))
    end

    return c
end

function Canvas:on_render(rows)
end

function Canvas:on_data_changed(data, key, newvalue, oldvalue)
end

function Canvas:update()
    if not self.hbuf then
        return
    end

    self._state = {
        highlights = { },
        linebase = 0,
        line = 1,
    }

    local rows = { }
    self:on_render(rows)
    self._state.linebase = #rows
    rows = vim.list_extend(rows, self:_render())

    if not self.options.height then -- Calculate height to fit model
        self.options.height = #rows
    end

    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", true)
        vim.api.nvim_buf_clear_namespace(self.hbuf, self.hns, 0, -1)
        vim.api.nvim_buf_set_lines(self.hbuf, 0, -1, false, rows)
    vim.api.nvim_buf_set_option(self.hbuf, "modifiable", false)

    local function hl(h, t)
        if not h then
            return nil
        end

        return vim.startswith(h, "#") and h or "#" .. bit.tohex(vim.api.nvim_get_hl_by_name(h, true)[t], 6)
    end

    for line, highlights in pairs(self._state.highlights) do
        for _, highlight in ipairs(highlights) do
            local n = ("highlight_%d_%d_%d"):format(line, highlight.colstart, highlight.colend)

            vim.api.nvim_set_hl(self.hns, n, {
                foreground = hl(highlight.foreground, "foreground"),
                background = hl(highlight.background, "background"),
                bold = highlight.bold or false,
            })

            vim.api.nvim_buf_add_highlight(self.hbuf, self.hns, n, line - 1, highlight.colstart, highlight.colend)
        end
    end
end

return Canvas

