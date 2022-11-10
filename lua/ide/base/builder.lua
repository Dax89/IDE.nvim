local Utils = require("ide.utils")
local Path = require("plenary.path")

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

function Builder:build(_, _)
    self.project:get_build_path():mkdir({parents = true, exists_ok = true})
end

function Builder:debug(_)
    self.project:get_build_path():mkdir({parents = true, exists_ok = true})
end

function Builder:create(data)
end

function Builder:run()
    local selcfg = self.project:get_selected_config()

    if selcfg then
        self:do_run_cmd(selcfg.command, selcfg, {cwd = vim.F.if_nil(selcfg.cwd, self.project:get_path(true))})
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

function Builder:do_run_cmd(cmd, runconfig, options)
    if type(cmd) == "string" then
        cmd = vim.split(cmd, " ")
    end

    if not vim.tbl_isempty(cmd) then
        self.project:new_job(cmd[1], vim.list_slice(cmd, 2), vim.tbl_extend("force", options or { }, {title = "Run - " .. runconfig.name, state = "run"}))
    end
end

function Builder:do_run(filepath, args, runconfig, options)
    self.project:new_job(filepath, args, vim.tbl_extend("force", options or { }, {title = "Run - " .. runconfig.name or Utils.get_filename(filepath), state = "run"}))
end

function Builder:check_and_run(filepath, args, runconfig, options)
    local p = Path:new(filepath)

    if not p:is_file() then
        self:build(nil, function(_, code)
            if code == 0 then
                self:do_run(p, args, runconfig, options)
            end
        end)
    else
        self:do_run(p, args, runconfig)
    end
end

function Builder:check_settings(cb, options)
    options = options or { }

    local selcfg = self.project:get_selected_config()
    local selruncfg = self.project:get_selected_runconfig()

    if (options.checkconfig == false or selcfg) and (options.checkrunconfig == false or selruncfg) then
        cb(self, selcfg, selruncfg)
        return
    end

    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self):popup(function()
            self:check_settings(cb, options) -- Check settings again
        end)
    end
end

function Builder:get_settings_dialog()
    local ok, d = pcall(require, "ide.projects." .. self.project:get_type() ..
                                 ".builders." .. self:get_type() ..
                                 ".settings")

    return ok and d or require("ide.internal.dialogs.configdialog")
end

return Builder
