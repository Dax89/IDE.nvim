local Theme = {
    primary = "Cursor",
    secondary = "String",
    accent = "Title",
    error = "ErrorMsg",
    selected = "Search",
}

local M = { }

function M._validate()
    local t = { }

    for k, v in pairs(Theme) do
        t[k] = {v, "table"}
    end

    vim.validate(t)
end

function M.set_theme(theme)
    Theme = vim.tbl_extend("force", Theme, theme or { })
    M._validate()
end

function M.get_color(c)
    return Theme[c] or c
end

function M.set_color(c, v)
    Theme[c] = v
end

return M

