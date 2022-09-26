local Utils = require("ide.utils")

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

function Builder:create()
end

function Builder:run()
    local Path = require("plenary.path")

    self:check_settings(function(_, _, target)
        self:check_and_run(Path:new(self.project:get_build_path(true), target), target)
    end)
end

function Builder:settings()
    local dlg = self:_get_settings_dialog()

    if dlg then
        dlg(self):popup()
    end
end

function Builder:on_ready()
end

function Builder:check_and_run(filepath, name)
    local Path = require("plenary.path")
    local p = Path:new(filepath)

    if not p:is_file() then
        self:build(nil, function(_, code)
            if code == 0 then
                self.project:new_job(p, nil, {title = "Run - " .. name or Utils.get_filename(p), state = "run"})
            end
        end)
    else
        self.project:new_job(p, nil, {title = "Run - " .. name or Utils.get_filename(p), state = "run"})
    end
end

function Builder:check_settings(cb)
    local currmode = self.project:get_mode()
    local currtarget = self.project:get_target()

    if currmode and currtarget then
        cb(self, currmode, currtarget)
        return
    end

    local dlg = self:_get_settings_dialog()

    if dlg then
        dlg(self):popup(function(data)
            self._project:set_mode(data.mode)
            self._project:set_target(data.target)
            vim.F.npcall(cb, self, data.mode, data.target)
        end)
    else
        self:_check_mode(cb)
    end
end

function Builder:_check_mode(cb)
    local currmode = self.project:get_mode()

    if not currmode or currmode == "" then
        vim.ui.select(self:get_modes(), {
            prompt = "Select Mode",
            format_item = function(mode)
                return currmode == mode and mode .. " - SELECTED" or mode
            end
        }, function(mode)
            if mode then
                self.project:set_mode(mode)
                self:_check_target(cb)
            end
        end)
    else
        self:_check_target(cb)
    end
end

function Builder:_check_target(cb)
    if not self.project:get_mode() then
        return
    end

    local currtarget = self.project:get_target()

    if not currtarget or currtarget == "" then
        vim.ui.select(self:get_targets(), {
            prompt = "Select Target",
            format_item = function(target)
                return currtarget == target and target .. " - SELECTED" or target
            end
        }, function(target)
            if target then
                self.project:set_target(target)
                self.project:write()
                vim.F.npcall(cb, self.project:get_mode(), target)
            end
        end)
    else
        cb(self, self.project:get_mode(), currtarget)
    end
end

function Builder:_get_settings_dialog()
    local ok, d = pcall(require, "ide.projects." .. self.project:get_type() ..
                                 ".builders." .. self:get_type() ..
                                 ".settings")
    return ok and d or nil
end

return Builder
