# ide.nvim
`ide.nvim` is born from parts of my personal NeoVim configuration and it aims to have nice Project Management, Build, and Debug support for various type of programming languages.

<ins>**NOTE:** This plugin is still under development, it can be unstable and API can change!</ins>

# Installation
```lua
use { "Dax89/ide.nvim",  requires = { {"nvim-lua/plenary.nvim"}
                                      {"rcarriga/nvim-notify"},   -- Notifications Popup (Optional)
                                      {"stevearc/dressing.nvim"}, -- Improved UI (Optional)
                                      {"mfussenegger/nvim-dap"} , -- DAP Support (Optional)
                                      {"rcarriga/nvim-dap-ui"} }  -- DAP-UI Support (Optional)
}
```

# Plugin initialization (with default configuration values)
By default `ide.nvim` doesn't provides any mapping, check the [sample configuration](https://github.com/Dax89/ide.nvim/wiki/Sample-Configuration) in order to configure them.

```lua
require("ide").setup({
    ignore_filetypes = { },
    root_patterns = {".git/"},
    shadow_build = false,
    auto_create = true,
    debug = false,
    build_dir = "build",
    project_file = "project.nvide",
    mappings = { }

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
                DapStopped    = {ctermbg = 0, fg ="#98c379"},
            },

            signs = {
                DapBreakpoint          = { text="", texthl="DapBreakpoint", numhl="DapBreakpoint" },
                DapBreakpointCondition = { text="ﳁ", texthl="DapBreakpoint", numhl="DapBreakpoint" },
                DapBreakpointRejected  = { text="", texthl="DapBreakpoint", numhl= "DapBreakpoint" },
                DapLogPoint            = { text="", texthl="DapLogPoint", numhl= "DapLogPoint" },
                DapStopped             = { text="", texthl="DapStopped", numhl= "DapStopped" },
            }
        },

        dapui = {
            enable = false
        }
    }
})
```

# Commands
- *IdeRecentProjects*: Show recent projects
- *IdeProjectCreate*: Open a dialog which allows to create new projects
- *IdeProjectWrite*: Save the project in `ide.nvim` format (uses `project_file` from config)

# API
*Coming Soon!*

# Related Projects
- [projectmgr](https://github.com/charludo/projectmgr.nvim)
- [project.nvim](https://github.com/ahmedkhalf/project.nvim)
- [neovim-cmake](https://github.com/Shatur/neovim-cmake)
