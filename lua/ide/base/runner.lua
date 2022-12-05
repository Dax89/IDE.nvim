local Utils = require("ide.utils")
local Async = require("plenary.async")
local Job = require("plenary.job")

local Runner = Utils.class()

function Runner:init(config)
    self.config = config
    self.state = { }
    self.jobs = { }
end

function Runner:is_busy()
    return not vim.tbl_isempty(self.jobs)
end

function Runner:set_state(s)
    if self.state[s] == nil then
        self.state[s] = 1
    else
        self.state[s] = self.state[s] + 1
    end
end

function Runner:unset_state(s)
    if self.state[s] ~= nil then
        self.state[s] = math.max(self.state[s] - 1, 0)
    end
end

function Runner:has_state(s)
    return self.state[s] ~= nil and self.state[s] > 0
end

function Runner:cancel()
    for _, job in ipairs(self.jobs) do
        job:shutdown()
    end
end

function Runner:_execute_async(command, args, cwd, options)
    options = options or { }

    local co = Async.wrap(function(callback)
        options.onexit = function(result, code)
            callback(result, code)
        end

        self:_execute(command, args, cwd, options)
    end, 1)

    return co()
end

function Runner:_open_quickfix()
    vim.cmd("copen")
end

function Runner:_scroll_quickfix()
    if vim.bo.buftype ~= "quickfix" then
        vim.api.nvim_command("cbottom")
    end
end

function Runner:_clear_quickfix(title)
    vim.fn.setqflist({ }, " ", {title = title})
end

function Runner:_append_quickfix(line)
    vim.fn.setqflist({ }, "a", {lines = {line}})
    self:_scroll_quickfix()
end

function Runner:_execute(command, args, cwd, options)
    if not args then
        args = { }
    elseif type(args) ~= "table" then
        args = { args }
    end

    options = options or { }

    if options.log ~= false then
        self:_open_quickfix()
        vim.api.nvim_command("wincmd p") -- Go Back to the previous window
        self:_clear_quickfix(vim.F.if_nil(options.title, command))
    end

    Job:new({
        command = tostring(command),
        args = args,
        cwd = cwd,

        on_start = vim.schedule_wrap(function(job)
            if options.log ~= false then
                self:_append_quickfix(">>> " .. job.command  .. " " .. table.concat(job.args, " "))
            end

            if options.state then
                self:set_state(options.state)
            end

            table.insert(self.jobs, {job, options})
        end),

        on_stdout = vim.schedule_wrap(function(_, data)
            if options.log ~= false then
                self:_append_quickfix(data)
            end
        end),

        on_stderr = vim.schedule_wrap(function(_, data)
            if options.log ~= false then
                self:_append_quickfix(data)
            end
        end),

        on_exit = vim.schedule_wrap(function(job, code)
            if options.log ~= false then
                self:_append_quickfix(">>> Terminated with code " .. tostring(code))
            end

            if options.state then
                self:unset_state(options.state)
            end

            self.jobs = vim.tbl_filter(function(item)
                return item[1] ~= job
            end, self.jobs)

            if vim.is_callable(options.onexit) then
                local res = job:result()

                if options.json then
                    if code ~= 0 then
                        options.onexit(nil, code)
                        return
                    end

                    res = vim.json.decode(table.concat(res, "\n"))
                end

                options.onexit(res, code)
            end
        end)
    }):start()
end

return Runner
