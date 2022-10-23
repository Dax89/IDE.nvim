local Path = require("plenary.path")
local Scan = require("plenary.scandir")
local Utils = require("ide.utils")

local function select_item(path, onchoice, options, level)
    level = level or 0

    local function is_root(p)
        if options.limitroot and level == 0 then
            return true
        end

        return p.sep == "\\" and string.match(p.filename, "^[A-Z]:\\?$") or p.filename == "/"
    end

    local items = vim.tbl_map(function(item)
        return Path:new(item)
    end, Scan.scan_dir(tostring(path), vim.tbl_extend("force", options, {depth = 1})))

    if not is_root(path) then
        table.insert(items, 1, "..")
    end

    if options.onlydirs then
        table.insert(items, 1, "<SELECT FOLDER>")
    end

    vim.ui.select(items, {
        prompt = path.filename,
        format_item = function(item)
            if type(item) ~= "string" then
                return (item:is_dir() and " " or " ") .. Utils.get_filename(item.filename)
            end
            return item
        end
    },
    function(choice)
        if choice then
            if choice == "<SELECT FOLDER>" then
                onchoice(path)
            elseif choice == ".." then
                if not is_root(choice) then
                    select_item(path:parent(), onchoice, options, level - 1)
                end
            elseif type(choice) == "table" and choice:is_dir() then
                select_item(Path:new(choice), onchoice, options, level + 1)
            elseif not options.onlydirs and (type(choice) == "table" and choice:is_file()) then
                onchoice(choice)
            end
        end
    end)
end

local PickerDialog = { }

function PickerDialog.select_folder(onchoice, options)
    options = options or { }
    select_item(Path:new(options.cwd or vim.loop.os_homedir()), onchoice, vim.tbl_extend("force", options, {onlydirs = true}))
end

function PickerDialog.select_file(onchoice, options)
    options = options or { }
    select_item(Path:new(options.cwd or vim.loop.os_homedir()), onchoice, vim.tbl_extend("force", options, {add_dirs = true}))
end

return PickerDialog
