local M = { }

function M.private_stash()
    return setmetatable({}, {__mode = "k"})
end

function M.class(base)
    if base and type(base) ~= "table" then
        error("Base class type must be a table, got '" .. type(base) .. "'")
    end

    local MT = {
        __index = base or nil,
        __call = function(self, ...)
            local inst = setmetatable({class = self}, {__index = self})

            if type(inst.init) == "function" then
                inst:init(...)
            end

            return inst
        end
    }

    return setmetatable({
        super = base,
        instanceof = function(self, c)
            if not c then
                error("Invalid Class Type")
            end

            if type(c) ~= "table" then
                error("Expected 'table', got '" .. type(c) .. "'")
            end

            if self.class == c then
                return true
            end

            if not self.super then
                return false
            end

            if self.super == c then
                return true
            end

            return self.super.instanceof and self.super:instanceof(c) or false
        end
    }, MT)
end

function M.get_number_of_cores()
    return #vim.tbl_keys(vim.loop.cpu_info())
end

function M.if_call(c, ...)
    if vim.is_callable(c) then
        c(...)
    end
end

function M.get_plugin_root()
    return require("plenary.path"):new(debug.getinfo(1).source:sub(2)):parent():parent():parent()
end

function M.os_open(arg)
    arg = tostring(arg)

    local uname = vim.loop.os_uname().sysname
    local cmd = nil

    if uname == "Windows" then
        cmd = {command = "cmd", args = {"/c", "start", arg}}
    elseif uname == "Darwin" then
        cmd = {command = "open", args = {arg}}
    elseif uname == "Linux" then
        cmd = {command = "xdg-open", args = {arg}}
    else
        M.notify("Unsupported Platform '" .. uname .. "'", "warn", {title = "OS Open"})
        return
    end

    require("plenary.job"):new({
        command = cmd.command,
        args = cmd.args,
    }):start()
end

function M.os_execute(cmd, args, cwd, options)
    local Job = require("plenary.job")

    return Job:new(vim.tbl_extend("keep", {
        command = cmd,
        args = args,
        cwd = cwd and tostring(cwd) or nil
    }, options or { })):sync()
end

function M.read_lines(filepath)
    local data = M.read_file(filepath)
    return vim.split(data, "\n")
end

function M.read_file(filepath)
    local f = require("io").open(tostring(filepath), "r")

    if f then
        local data = f:read("*all")
        f:close()
        return data
    end

    error("Cannot read file '" .. tostring(filepath) .. "'")
end

function M.write_file(filepath, data)
    local f = require("io").open(tostring(filepath), "w")

    if f then
        f:write(data)
        f:close()
    else
        print("Cannot write file '" .. tostring(filepath) .. "'")
    end
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

function M.if_nilempty(v)
    return v == nil or #v <= 0
end

function M.notify(s, category, options)
    options = options or { }

    local ok, notify = pcall(require, "notify")

    if ok then
        notify(s, category, options or { })
    else
        vim.notify(s, category)
    end
end

return M
