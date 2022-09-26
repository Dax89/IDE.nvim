local Utils = require("ide.utils")
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

function Runner:_execute(command, args, cwd, options)
    if type(args) ~= "table" then
        args = { args }
    end

    options = options or { }

    local res, code = Job:new({
        command = command,
        args = args,
        cwd = cwd,

        on_start = function()
            if options.state then
                self.set_state(options.state)
            end
        end,

        on_exit = function()
            if options.state then
                self.unset_state(options.state)
            end
        end
    }):sync()

    if options.json then
        if code ~= 0 then
            return nil, code
        end

        res = vim.json.decode(table.concat(res, "\n")) -- NOTE: Multiline Output?
    end

    return res, code
end

function Runner:cancel()
    for _, job in ipairs(self.jobs) do
        job:shutdown()
    end
end

function Runner:_new_job(command, args, cwd, options)
    if not args then
        args = { }
    elseif type(args) ~= "table" then
        args = { args }
    end

    options = options or { }

    local j = Job:new({
        command = tostring(command),
        args = args,
        cwd = cwd,

        on_start = vim.schedule_wrap(function(job)
            vim.fn.setqflist({}, "r", {
                title = options.title,
                lines = {">>> " .. job.command  .. " " .. table.concat(job.args, " ")}
            })

            vim.api.nvim_command((self.config.quickfix.pos or "bel") .. " copen")

            -- HACK: Delay window repositioning a bit, copen doesn't wait
            vim.defer_fn(function()
                vim.api.nvim_command("wincmd p")
            end, 200)

            if options.state then
                self:set_state(options.state)
            end

            table.insert(self.jobs, {job, options})
        end),

        on_stdout = vim.schedule_wrap(function(_, data)
            vim.fn.setqflist({}, "a", {
                title = options.title,
                lines = {data}
            })

            vim.api.nvim_command("cbottom")
        end),

        on_stderr = vim.schedule_wrap(function(_, data)
            vim.fn.setqflist({}, "a", {
                title = options.title,
                lines = {data}
            })

            vim.api.nvim_command("cbottom")
        end),

        on_exit = vim.schedule_wrap(function(job, code)
            vim.fn.setqflist({}, "a", {
                title = options.title,
                lines = {">>> " .. " Terminated with code " .. tostring(code)}
            })

            vim.api.nvim_command("cbottom")

            if options.state then
                self:unset_state(options.state)
            end

            self.jobs = vim.tbl_filter(function(item)
                return item[1] ~= job
            end, self.jobs)

            vim.F.npcall(options.onexit, self, code)
        end)
    })

    if options.sync then
        j:sync()
    else
        j:start()
    end

    return j
end

return Runner
