local Utils = require("ide.utils")

local Model = Utils.class()

function Model:init(options)
    self._components = { }
    self._options = options or { }
    self.data = self:_reset()
end

function Model:_reset()
    return setmetatable({
        _data = { },
        _components = { },
        add_component = function(m, c)
            m._components[c.id] = c
        end,
        get_component = function(m, id)
            return m._components[id]
        end,
        get_data = function(m)
            return m._data
        end
    }, {
        __index = function(t, k)
            return rawget(t, "_data")[k]
        end,
        __newindex = function(t, k, v)
            local oldv = rawget(t._data, k)
            if oldv ~= v then
                rawset(t._data, k, v)

                local c = t:get_component(k)

                if c then
                    c:set_value(v)
                end

                if vim.is_callable(self._options.change) then
                    self._options.change(t, k, v, oldv)
                end
            end
        end
    })
end

function Model:validate(keys)
    keys = keys or vim.tbl_keys(rawget(self.data, "_data"))

    if vim.tbl_isempty(keys) then
        return false
    end

    for _, k in ipairs(keys) do
        local c = self.data:get_component(k)
        if c.optional ~= true and (self.data[k] == nil or self.data[k] == "") then
            return false
        end
    end

    return true
end

function Model:get_components()
    return self._components
end

function Model:each_component(cb, components)
    for i, row in ipairs(components or self._components) do
        local cl = vim.tbl_islist(row) and row or {row}

        for _, c in ipairs(cl) do
            cb(c, i)
        end
    end
end

function Model:set_components(components)
    self._components = { }
    self.data = self:_reset()

    self:each_component(function(c, i)
        c.row = i - 1
        table.insert(self._components, c)

        if c.id then
            if self.data:get_component(c.id) then
                error("Duplicate id '" .. c.id .. "'")
            end

            self.data:add_component(c)
            self.data[c.id] = c:get_value()
        end
    end, components)
end

return Model

