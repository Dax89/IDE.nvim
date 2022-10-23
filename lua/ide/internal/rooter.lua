local Utils = require("ide.utils")
local Path = require("plenary.path")
local Log = require("ide.log")

local Rooter = Utils.class()

function Rooter:init(ide)
    self.ide = ide
end

function Rooter:_check_pattern(path, pattern)
    local isdir = vim.endswith(pattern, "/")
    local n = isdir and pattern:gsub(0, -2) or pattern
    local p = Path:new(path, n)
    return isdir and p:is_dir() or p:is_file()
end

function Rooter:_find_pattern_in_fs(filepath, rootpattern)
    if vim.is_callable(rootpattern) then
        return rootpattern(filepath)
    else
        local patterns = vim.tbl_islist(rootpattern) and rootpattern or vim.tbl_keys(rootpattern)

        for _, pattern in ipairs(patterns) do
            if self:_check_pattern(filepath, pattern) then
                return pattern
            end
        end
    end

    return nil
end

function Rooter:_find_root_in_fs(filepath, rootpattern)
    for _, cp in ipairs(filepath:parents()) do
        if self:_find_pattern_in_fs(cp, rootpattern) then
            return tostring(cp)
        end
    end

    return tostring(filepath)
end

function Rooter:_get_config_pattern()
    return vim.list_extend({self.ide.config.project_file}, self.ide.config.root_patterns)
end

function Rooter:_check_git_repo(p)
    local gitfound = false

    -- Check if is a GIT Submodule
    Log.debug("Rooter:find_rootpath(): Searching root in GIT submodules")
    local gitroot, ret = Utils.os_execute("git", {"rev-parse", "--show-superproject-working-tree"}, tostring(p))

    -- Check if is a GIT Repo
    if ret == 0 and vim.tbl_isempty(gitroot) then
        Log.debug("Rooter:find_rootpath(): Searching root dir in GIT repo")
        gitroot, ret = Utils.os_execute("git", {"rev-parse", "--show-toplevel"}, tostring(p))
    end

    gitfound = ret == 0 and not vim.tbl_isempty(gitroot)

    if gitfound then
        p = gitroot[1]
    end

    return gitfound, p
end

function Rooter:find_rootpath(filepath, filetype, projecttype)
    local rootpattern = vim.F.if_nil(projecttype.get_root_pattern(), self:_get_config_pattern())
    local p = Path:new(tostring(filepath))
    Log.debug("Rooter:find_rootpath(): FilePath is '" .. tostring(filepath) .. "'")

    local gitfound = false

    if self.ide:has_integration("git") then
        gitfound, p = self:_check_git_repo(p)
    end

    if not gitfound then
        Log.debug("Rooter:find_rootpath(): Searching root in FS")
        p = self:_find_root_in_fs(filepath, rootpattern)
    end

    assert(p, "Invalid project root")
    local pattern = self:_find_pattern_in_fs(p, rootpattern)

    if not pattern then
        Log.warn("Rooter:find_rootpath(): Pattern NOT FOUND in " .. tostring(p))
        return nil
    end

    Log.debug("Rooter:find_rootpath(): RootPath is '" .. tostring(p) .. "', selected pattern: '" .. vim.inspect(pattern) .. "'")

    local name = Utils.get_filename(p)
    local projfile = Path:new(p, self.ide.config.project_file)

    if projfile:is_file() then
        local nvide = Utils.read_json(projfile)

        if nvide.type ~= filetype then
            return nil
        end

        Log.debug("Rooter:find_rootpath(): '" .. self.ide.config.project_file .. "' loaded, name is '" .. nvide.name .. "'")
        name = nvide.name
    end

    local cfg = { }

    if vim.is_callable(rootpattern) then
        cfg = type(pattern) == "table" and pattern or { }
    elseif type(rootpattern) == "table" then
        cfg = rootpattern[pattern] or { }
    end

    return {
        name = name,
        root = p,
        config = cfg,
    }
end

return Rooter
