local Utils = require("ide.utils")
local Path = require("plenary.path")
local Async = require("plenary.async")

local Builder = Utils.class()

function Builder:init(project)
    self.project = project
end

function Builder:get_type()
    return "nvide"
end

function Builder:rebuild()
    self.project:get_build_path():rmdir()
    self:build()
end

function Builder:configure()
    self.project:get_build_path():mkdir({parents = true, exists_ok = true})
end

function Builder:build()
    self.project:get_build_path():mkdir({parents = true, exists_ok = true})
end

function Builder:debug(_)
    self.project:get_build_path():mkdir({parents = true, exists_ok = true})
end

function Builder:create(_)
end

function Builder:run()
    local _, runcfg = self:check_settings()

    if runcfg then
        self:do_run_cmd(runcfg.command, runcfg.name, {
            cwd = vim.F.if_nil(runcfg.cwd, self.project:get_path(true))
        })
    else
        vim.notify("Invalid run configuration")
    end
end

function Builder:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        if not self.project.data.builder then
            dlg(self, nil, {showcommand = true}):popup()
        else
            dlg(self):popup()
        end
    end
end

function Builder:on_ready()
end

function Builder:on_config_changed(_)
end

function Builder:on_runconfig_changed(_)
end

function Builder:do_run_cmd(cmd, args, options)
    options = options or { }
    local title = "Run - " .. vim.F.if_nil(options.title, cmd)
    self.project:execute(cmd, args, vim.tbl_extend("force", options, {title = title, state = "run"}))
end

function Builder:do_run(filepath, args, options)
    options = options or { }

    local p = Path:new(filepath)
    local title = "Run - " .. vim.F.if_nil(options.title, Utils.get_filename(p))

    if not p:is_file() or options.build == true then
        self:build()
    end

    self.project:execute(p, args, vim.tbl_extend("force", options, {
        title = title,
        state = "run",
        cwd = tostring(vim.F.if_nil(options.cwd, options.source and self.project:get_path() or self.project:get_build_path())),
    }))
end

function Builder:_check_settings(options, c, callback)
    local selcfg = self.project:get_selected_config()
    local selruncfg = self.project:get_selected_runconfig()

    if (options.checkconfig == false or selcfg) and (options.checkrunconfig == false or selruncfg) then
        callback({config = selcfg, runconfig = selruncfg})
        return
    end

    if c > 0 then
        callback(nil)
        return -- Avoid infinite recursion
    end

    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self):exec()
        self:_check_settings(options, c + 1, callback) -- Check settings again
    end
end

function Builder:check_settings(options)
    local co = Async.wrap(self._check_settings, 4)
    return co(self, options or { }, 0)
end

function Builder:get_settings_dialog()
    if self.project:is_virtual() then
        return require("ide.internal.dialogs.configdialog")
    end

    local ok, d = pcall(require, "ide.projects." .. self.project:get_type() ..
                                 ".builders." .. self:get_type() ..
                                 ".settings")

    return ok and d or require("ide.internal.dialogs.configdialog")
end

return Builder
