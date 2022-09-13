local M = { }

function M.class(base)
    if base and type(base) ~= "table" then
        error("Base class type must be a table, got '" .. type(base) .. "'")
    end

    local MT = {
        __index = base or nil,
        __call = function(self, ...)
            if type(self.init) == "function" then
                self:init(...)
            end
            return self
        end
    }

    return setmetatable({ }, MT)
end

function M.get_number_of_cores()
    return #vim.tbl_keys(vim.loop.cpu_info())
end

function M.get_plugin_root()
    return require("plenary.path"):new(debug.getinfo(1).source:sub(2)):parent():parent():parent()
end

function M.os_execute(cmd, args, cwd, options)
    local Job = require("plenary.job")

    return Job:new(vim.tbl_extend("keep", {
        command = cmd,
        args = args,
        cwd = cwd
    }, options or { })):sync()
end

function M.read_file(filepath)
    local io = require("io")
    local f = io.open(tostring(filepath), "r")
    local data = f:read("*all")
    f:close()
    return data
end

function M.write_file(filepath, data)
    local io = require("io")
    local f = io.open(tostring(filepath), "w")
    f:write(data)
    f:close()
end

function M.read_json(filepath)
    return vim.json.decode(M.read_file(filepath))
end

function M.write_json(filepath, json)
    M.write_file(filepath, vim.json.encode(json))
end

function M.get_filename(p)
    return vim.fn.fnamemodify(tostring(p), ":t")
end

function M.list_reverse(l)
    local rev = {}

    for i=#l, 1, -1 do
        rev[#rev + 1] = l[i]
    end

    return rev
end

return M
