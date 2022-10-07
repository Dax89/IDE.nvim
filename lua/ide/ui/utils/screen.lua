local M = { }

function M._calc_p(p)
    if type(p) == "string" and vim.endswith(p, "%") then
        p = tonumber(p:sub(0, -2)) / 100
    end

    if type(p) ~= "number" then
        p = 1
    end

    return p
end

function M.get_width(p)
    return math.ceil(vim.o.columns * M._calc_p(p))
end

function M.get_height(p)
    return math.ceil(vim.o.lines * M._calc_p(p))
end

return M
