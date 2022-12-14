return {
    ignore_filetypes = { },
    root_patterns = {".git/"},
    auto_save = true,
    shadow_build = false,
    debug = false,
    project_file = "project.nvide",

    quickfix = {
        pos = "bel"
    },

    integrations = {
        dap = {
            enable = false,
            config = { },

            highlights = {
                DapBreakpoint = {ctermbg = 0, fg = "#993939"},
                DapLogPoint   = {ctermbg = 0, fg = "#61afef"},
                DapStopped    = {ctermbg = 0, fg = "#98c379"},
            },

            signs = {
                DapBreakpoint          = { text="", texthl="DapBreakpoint", numhl= "DapBreakpoint" },
                DapBreakpointCondition = { text="ﳁ", texthl="DapBreakpoint", numhl= "DapBreakpoint" },
                DapBreakpointRejected  = { text="", texthl="DapBreakpoint", numhl= "DapBreakpoint" },
                DapLogPoint            = { text="", texthl="DapLogPoint",   numhl= "DapLogPoint" },
                DapStopped             = { text="", texthl="DapStopped",    numhl= "DapStopped" },
            }
        },

        dapui = {
            enable = false
        },

        git = {
            enable = false
        }
    }
}
