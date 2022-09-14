local Utils = require("ide.utils")

local Canvas = Utils.class()

function Canvas:init(options)
    self.options = options

    self.hbuf = vim.api.nvim_create_buf(false, true)
    self._namespace = vim.api.nvim_create_namespace(("namespace_%d"):format(self.hbuf))
    vim.api.nvim_buf_set_option(self.hbuf, "filetype", "ide-ui")
end

function Canvas:component(id, type, label, key, options)
    return vim.tbl_extend("force", options or { }, {
        id = id,
        type = type,
        label = label,
        key = key
    })
end

function Canvas:get_width()
    return self.options.width
end

function Canvas:get_height()
    return self.options.height
end

function Canvas:_close_buffer()
    if self.hbuf then
        vim.api.nvim_buf_delete(self.hbuf, {force = true})
    end
end

function Canvas:_init_component(options)
    return vim.tbl_extend("force", {
        type = "text",
        align = "left",
        width = self:get_width()
    }, options or { })
end

function Canvas:_render_text(component)
    local text = component.label .. (component.value and (" " .. component.value) or "")
    local len = #text

    if component.key then
        len = len + #component.key + 1
    end

    if component.iconleft then
        len = len + #component.iconleft + 1
    end

    if component.iconright then
        len = len + #component.iconright + 1
    end

    local pad, s = string.rep(" ", math.max(math.ceil((component.width - len)), 0)), ""

    if component.align == "center" then
        s = pad:sub(0, #pad / 2) .. text .. pad:sub(0, #pad / 2)
    elseif component.align == "right" then
        s = pad .. text
    else
        s = text .. pad
    end

    if component.iconleft then
        s = component.iconleft .. " " .. s
    end

    if component.iconright then
        s = s .. " " .. component.iconright
    end

    if component.key then
        s = s .. " " .. component.key
    end

    return s
end

function Canvas:_render_button(component)
    return self:_render_text(component)
end

function Canvas:_render_folder(component)
    return self:_render_text(vim.tbl_extend("force", component, {
        iconright = "…"
    }))
end

function Canvas:_render_select(component)
    return self:_render_text(vim.tbl_extend("force", component, {
        iconright = ""
    }))
end

function Canvas:_render_hline(component)
    return string.rep("⎯", component.width)
end

function Canvas:render_component(component)
    component = self:_init_component(component)
    local cb = self["_render_" .. component.type]

    if not cb then
        error("Unsupported component type '" .. component.type .. "'")
    end

    return cb(self, component)
end

function Canvas:render_columns(components, width)
    width = width or self:get_width()
    local colw, columns = width / #components, { }

    for i, component in ipairs(components) do
        local needseparator = i < #components
        table.insert(columns, self:render_component(vim.tbl_extend("force", component, {width = colw - (needseparator and 1 or 0)})))

        if needseparator then
            table.insert(columns, " ")
        end
    end

    return table.concat(columns)
end

return Canvas

