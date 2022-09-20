local M = { }

function M.len(s)
    return vim.str_utfindex(s)
end

function M.char(s, idx)
    local b = vim.str_byteindex(s, idx)
    local e = vim.str_byteindex(s, idx + 1)
    return s:sub(b + 1, e)
end

function M.rep(s, n)
    local P = vim.str_byteindex(s, 1)
    local res = ""

    for _ = 1, n do
        res = res .. s:sub(1, P) .. s:sub(P + 1)
    end

    return res
end

return M
