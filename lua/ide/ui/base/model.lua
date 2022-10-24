local Utils = require("ide.utils")

local private = Utils.private_stash()
local Model = Utils.class()

function Model:init(options)
    options = options or { }

    private[self] = {
        change = options.change
    }

    self:reset()
end

function Model:reset()
    self.data = self:_reset()
end

function Model:_reset()
    return setmetatable({
        _data = { },
        _components = { },
        set_component = function(m, c)
            m._components[c.id] = c
        end,
        remove_component = function(m, id)
            m._components[id] = nil
            m._data[id] = nil
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

                if vim.is_callable(private[self].change) then
                    private[self].change(t, k, v, oldv)
                end
            end
        end
    })
end

function Model:validate(keys)
    keys = keys or vim.tbl_keys(rawget(self.data, "_data"))

    if vim.tbl_isempty(keys) then
        return true
    end

    for _, k in ipairs(keys) do
        local c = self.data:get_component(k)
        if c.optional ~= true and (self.data[k] == nil or self.data[k] == "") then
            return false
        end
    end

    return true
end

function Model:remove_component(id)
    if type(id) == "string" then
        self.data:remove_component(id)
    end
end

function Model:set_component(c)
    if c.id then
        self.data:set_component(c)
        self.data[c.id] = c:get_value()
        return true
    end

    return false
end

function Model:check_component(c)
    if c.id and not self.data:get_component(c.id)then
        return self:set_component(c)
    end

    return false
end

return Model

