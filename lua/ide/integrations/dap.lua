local M = { }

function M._setup_ui(config, dap)
    local ok, dapui = pcall(require, "dapui")

    if not ok then
        error("DAP-UI plugin is not installed")
    end

    dapui.setup(config.integrations.dapui.config)

    dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
    end

    dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
    end

    dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
    end
end

function M.setup(config)
    if not config.integrations.dap or not config.integrations.dap.enable then
        return
    end

    local ok, dap = pcall(require, "dap")

    if not ok then
        error("DAP plugin is not installed")
    end

    -- Copy DAP Configuration
    for k, v in pairs(config.integrations.dap.config) do
        dap[k] = v
    end

    if type(config.integrations.dap.highlights) == "table" then
        for n, hl in pairs(config.integrations.dap.highlights) do
            vim.api.nvim_set_hl(0, n, hl)
        end
    end

    if type(config.integrations.dap.signs) == "table" then
        for n, s in pairs(config.integrations.dap.signs) do
            vim.fn.sign_define(n, s)
        end
    end

    if config.integrations.dapui and config.integrations.dapui.enable then
        M._setup_ui(config, dap)
    end
end

return M
