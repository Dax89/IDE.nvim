<p align="center">
  <a href="https://github.com/Dax89/ide.nvim">
    <img alt="IDE.NVim" height="125" src="https://user-images.githubusercontent.com/1503603/192603647-62424945-9930-4622-95a0-99f1b0bd9543.png">
  </a>
  <br>
  <img src="https://img.shields.io/github/stars/Dax89/ide.nvim?style=for-the-badge">
  <img src="https://img.shields.io/github/license/Dax89/ide.nvim?style=for-the-badge">
  <img src="https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white">
  <br>
  <br>
  Nice Project Management, Build, and Debug support for various type of programming languages.<br>
<img src="https://user-images.githubusercontent.com/1503603/196044470-2c2b42d1-5960-4f54-8a89-9761e24e5f46.png" width="45%"></img> <img src="https://user-images.githubusercontent.com/1503603/194845734-66b6a95d-ca9e-4ec0-9790-4175f1b0924d.png" width="45%"></img> <img src="https://user-images.githubusercontent.com/1503603/194845741-c3ef1237-31eb-4f2c-8cf2-bf5e8256af34.png" width="45%"></img> <img src="https://user-images.githubusercontent.com/1503603/194845747-7e60bf17-4bd0-4cbb-8113-c5e3b2edca5d.png" width="45%"></img> 
</p>

# Installation
```lua
use {
  "Dax89/IDE.nvim",  
  requires = { 
       {"nvim-lua/plenary.nvim"},
       {"rcarriga/nvim-notify"},   -- Notifications Popup (Optional)
       {"stevearc/dressing.nvim"}, -- Improved UI (Optional)
       {"mfussenegger/nvim-dap"} , -- DAP Support (Optional)
       {"rcarriga/nvim-dap-ui"},   -- DAP-UI Support (Optional)
    }
}
```

# Plugin initialization (with default configuration values)
By default `ide.nvim` doesn't provides any mapping, check the [sample configuration](https://github.com/Dax89/ide.nvim/wiki/Sample-Configuration) in order to configure them.

```lua
require("ide").setup({
    ignore_filetypes = { },
    root_patterns = {".git/"},
    shadow_build = false,
    debug = false,
    project_file = "project.nvide",
    mappings = { },

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

        dapui = { enable = false },
        git = { enable = false },
    }
})
```

# UI Keybinds
- `z`: Show actions (used in Tabs component, it's the bottom left button)
- `A`: Accept (used in Dialog and Tabs components, it's the bottom right button)
- `Ctrl-H`: Show components' keybinds
- `Z`: Move to previous tab/wizard step
- `M`: Move to next tab/wizard step
- `hjkl` and `arrow keys`: row/column selection for Table
- `Enter` and `Left Click`: Triggers the component's default event

# Commands
- `IdeRecentProjects`: Show recent projects
- `IdeProjectCreate`: Open a dialog which allows to create new projects
- `IdeProjectWrite`: Save the project in `ide.nvim` format (uses `project_file` from config)
- `IdeProjectSettings`: Open current project's settings
- `IdeProjectDebug`: Debug the current project
- `IdeProjectRun`: Run the current project
- `IdeProjectConfigure`: Configure the current project

# API
`require("ide")` provides these functions:
- `setup([config])`: Initialize and configure plugin
- `get_active_project()`: Returns the active project or `nil`
- `get_projects()`: Returns a list of the loaded projects or `{}`

Check the [Wiki](https://github.com/Dax89/IDE.nvim/wiki) for detailed documentation.

# Related Projects
- [projectmgr](https://github.com/charludo/projectmgr.nvim)
- [project.nvim](https://github.com/ahmedkhalf/project.nvim)
- [neovim-cmake](https://github.com/Shatur/neovim-cmake)
