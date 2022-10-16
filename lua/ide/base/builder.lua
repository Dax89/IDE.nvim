local Utils = require("ide.utils")
local Path = require("plenary.path")

local Builder = Utils.class()

function Builder:init(project)
    self.project = project
end

function Builder:get_type()
    error("Builder:get_type() is abstract")
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
end

function Builder:settings()
    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self):popup()
    end
end

function Builder:on_ready()
end

function Builder:do_run_cmd(cmd, config, options)
    if type(cmd) == "string" then
        cmd = vim.split(cmd, " ")
    end

    if not vim.tbl_isempty(cmd) then
        self.project:new_job(cmd[1], vim.list_slice(cmd, 2), vim.tbl_extend("force", options or { }, {title = "Run - " .. config.name, state = "run"}))
    end
end

function Builder:do_run(filepath, args, config, options)
    self.project:new_job(filepath, args, vim.tbl_extend("force", options or { }, {title = "Run - " .. config.name or Utils.get_filename(filepath), state = "run"}))
end

function Builder:check_and_run(filepath, args, config)
    local p = Path:new(filepath)

    if not p:is_file() then
        self:build(nil, function(_, code)
            if code == 0 then
                self:do_run(p, args, config)
            end
        end)
    else
        self:do_run(p, args, config)
    end
end

function Builder:check_settings(cb)
    local selcfg = self.project:get_selected_config()

    if selcfg then
        cb(self, selcfg)
        return
    end

    local dlg = self:get_settings_dialog()

    if dlg then
        dlg(self):popup(function()
            self:check_settings(cb) -- Check settings again
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
