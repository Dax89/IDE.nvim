local Rooter = require("ide.internal.rooter")
local Utils = require("ide.utils")
local Path = require("plenary.path")
local Log = require("ide.log")

local IDE = Utils.class()

function IDE:init(config)
    self._storage = Path:new(vim.fn.stdpath("data"), "ide")
    self.config = config or { }
    self.active = nil
    self.projects = { }
    self.rooter = Rooter(self)

    self._storage:mkdir({parents = true, exists_ok = true})
    require("ide.integrations.dap").setup(config)
end

function IDE:has_integration(name)
    return self.config.integrations[name] and self.config.integrations[name].enable == true
end

function IDE:load_recents()
    local recentspath = Path:new(self._storage, "recents.json")
    local recents = { }

    if recentspath:is_file() then
        recents = vim.tbl_filter(function(proj) -- Filter deleted projects
            return Path:new(proj.root, self.config.project_file):is_file()
        end, Utils.read_json(recentspath))
    end

    return recents, recentspath
end

function IDE:_update_recents(project)
    if project:is_virtual() then
        return
    end

    local recents, recentspath = self:load_recents()
    local p, idx  = project:get_path(true), -1

    for i, proj in ipairs(recents) do
        if proj.root == p then
            idx = i
            break
        end
    end

    if idx ~= -1 then
        table.remove(recents, idx)
    end

    table.insert(recents, {root = p, name = project:get_name()})
    Utils.write_json(recentspath, recents)
end

function IDE:get_active()
    return self.active and self.projects[self.active] or nil
end

function IDE:get_projects()
    return vim.tbl_values(self.projects)
end

function IDE:pick_file(rootdir)
    local PickerDialog = require("ide.ui.dialogs.picker")
    local p = Utils.read_json(Path:new(tostring(rootdir), self.config.project_file))

    PickerDialog.select_file(function(filepath)
        self:project_check(filepath, p.type)
        vim.api.nvim_command(":e " .. tostring(filepath))

        vim.defer_fn(function()
            self:get_active():on_ready()
        end, 1000)
    end, {cwd = rootdir, limitroot = true})
end

function IDE:_check_loaded(filepath)
    local cwd = vim.fn.getcwd()

    for _, p in ipairs(filepath:parents()) do
        if self.projects[p] ~= nil then

            if cwd ~= p then
                vim.api.nvim_set_current_dir(p)
            end

            if self.active ~= p then
                self.active = p
                Log.debug("IDE._check_loaded(): Project '" .. self.projects[p]:get_name() .. "' selected")
            else
                Log.debug("IDE._check_loaded(): Project '" .. self.projects[p]:get_name() .. "' already loaded, skipping...")
            end

            return true
        end
    end

    return false
end

function IDE:_check_projectfile(filepath)
    for _, p in ipairs(filepath:parents()) do
        local fp = Path:new(p, self.config.project_file)

        if fp:is_file() then
            Log.debug("IDE._check_projectfile(): '" .. self.config.project_file .. "' found in '" .. p .. "'")
            local projcfg = Utils.read_json(fp)

            return {
                name = projcfg.name,
                root = p,
                config = projcfg,
            }
        end
    end

    return nil
end

function IDE:project_check(filepath, filetype)
    if #filetype == 0 or vim.tbl_contains(self.config.ignore_filetypes, filetype) then
        return
    end

    -- HACK: Workaround for empty 'p' when filepath is 'Path'
    local p = type(filepath) == "table" and filepath or Path:new(filepath)

    if not p:exists() or self:_check_loaded(p) then
        return
    end

    local projcfg = self:_check_projectfile(p)
    local ok, ProjectType = pcall(require, string.format("ide.projects.%s", projcfg and projcfg.type or filetype))

    if not ok then
        Log.debug("IDE.project_check(): Project not found for filetype '" .. filepath .. "' loading default")
        ProjectType = require("ide.base.project") -- Try to guess a generic project
    end

    if not projcfg then
        projcfg = self.rooter:find_rootpath(p:is_file() and p:parent() or p, filetype, ProjectType)
    end

    if projcfg then
        if not self.projects[projcfg.root] then
            local project = ProjectType(self.config, projcfg.root, projcfg.name, projcfg.config.builder)
            self.projects[projcfg.root] = project
            self:_update_recents(project)

            vim.defer_fn(function()
                project:on_ready()
                project:write()
            end, 1000)
        else
            Log.debug("IDE.project_check(): Project: '" .. self.project[projcfg.root] .. "' already loaded, skipping...")
        end

        self.active = projcfg.root

        if vim.fn.getcwd() ~= projcfg.root then
            vim.api.nvim_set_current_dir(projcfg.root)
        end
    else
        Log.debug("IDE.project_check(): File '" .. Utils.get_filename(p) .. "' doesn't belong to any project")
        self.active = nil
    end
end

function IDE:project_create()
    local Dialogs = require("ide.internal.dialogs")
    Dialogs.CreateProjectDialog(self):popup()
end

function IDE:project_configure()
    if self.active then
        self:get_active():configure()
    end
end

function IDE:project_build()
    if self.active then
        self:get_active():build()
    end
end

function IDE:project_run()
    if self.active then
        self:get_active():run()
    end
end

function IDE:project_debug()
    if self.active then
        self:get_active():debug()
    end
end

function IDE:project_settings()
    if self.active then
        self:get_active():settings()
    end
end

function IDE:project_write()
    if self.active then
        self:get_active():write()
    end
end

local ide = nil

local function setup(config)
    config = vim.tbl_deep_extend("force", require("ide.config"), config or { })

    if type(config.debug) == "string" then
        Log.level = config.debug
    else
        Log.level = config.debug and "trace" or "info"
    end

    ide = IDE(config)
    local groupid = vim.api.nvim_create_augroup("NVimIDE", {clear = true})

    vim.api.nvim_create_autocmd("BufEnter", {
        group = groupid,
        nested = true,
        callback = function(arg)
            if #arg.file > 0 then
                ide:project_check(arg.file, vim.api.nvim_buf_get_option(0, "filetype"))
            end
        end })

    vim.api.nvim_create_user_command("IdeRecentProjects", function()
        local ProjectsDialog = require("ide.internal.dialogs.projectsdialog")

        local dlgprojects = ProjectsDialog(ide, {
            change = function(t)
                ide:pick_file(t:get_current_row().root)
            end
        })

        dlgprojects:show()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectCreate", function()
        ide:project_create()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectWrite", function()
        ide:project_write()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectSettings", function()
        ide:project_settings()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectDebug", function()
        ide:project_debug()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectRun", function()
        ide:project_run()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectBuild", function()
        ide:project_build()
    end, { })

    vim.api.nvim_create_user_command("IdeProjectConfigure", function()
        ide:project_configure()
    end, { })

    if type(config.mappings) == "table" then
        for key, cb in pairs(config.mappings) do
            vim.keymap.set("n", key, function()
                local p = ide:get_active()
                if p then
                   cb(p)
                end
            end)
        end
    end
end

return {
    setup = setup,
    get_active_project = function()
        return ide:get_active()
    end,
    get_projects = function()
        return ide:get_projects()
    end
}

