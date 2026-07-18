# llaunchd

Lua-powered launchd service manager for macOS.

Write service definitions as Lua tables, get launchd plists.

## Install

Already symlinked at `~/tools/llaunchd`.

## Usage

```
llaunchd list                  # List all services
llaunchd status <name>         # Show service status
llaunchd install [name]        # Generate plist (all or one)
llaunchd load <name>           # Load into launchctl
llaunchd unload <name>         # Unload from launchctl
llaunchd log <name>            # Tail log file
llaunchd help                  # Show help
```

## Service Files

Place `.lua` files in `~/.llaunchd/services/`:

```lua
-- ~/.llaunchd/services/myagent.lua
return defineAgent {
    Label   = "com.example.myagent",
    Program = "/usr/local/bin/mytool --flag",
    RunAtLoad = true,
    Restart = "on-failure",
    StdOut  = "/tmp/myagent.log",
    Env     = { PATH = "/usr/local/bin:/usr/bin:/bin" },
}
```

Then:
```bash
llaunchd install        # generate plists
llaunchd load myagent   # load into launchctl
```

## LSP Type Checking

Add the definition file to your editor:

**VS Code** (`.vscode/settings.json`):
```json
{
  "Lua.workspace.library": [
    "~/Code/Lua/llaunchd/llaunchd/llaunchd.d.lua"
  ]
}
```

**Neovim**:
```lua
require('lspconfig').lua_ls.setup {
  settings = { Lua = { workspace = { library = {
    vim.fn.expand("~/Code/Lua/llaunchd/llaunchd/llaunchd.d.lua")
  } } } }
}
```

Then `defineAgent {}` provides autocomplete and type checking.

## Config Keys

| Key | Maps To | Description |
|-----|---------|-------------|
| `Label` | `Label` | Reverse-DNS identifier (required) |
| `Program` | `ProgramArguments` | Command as string, auto-split |
| `ProgramArguments` | `ProgramArguments` | Command as array (alternative) |
| `RunAtLoad` | `RunAtLoad` | Start at boot |
| `Restart` | `KeepAlive` | `"always"`, `"on-failure"`, `"never"` |
| `KeepAlive` | `KeepAlive` | Raw launchd KeepAlive (overrides Restart) |
| `StdOut` | `StandardOutPath` | Stdout log path |
| `StdErr` | `StandardErrorPath` | Stderr log path |
| `Env` | `EnvironmentVariables` | Environment variables |
| `WatchPaths` | `WatchPaths` | Restart on path changes |
| `WorkingDirectory` | `WorkingDirectory` | Working directory |
| `ProcessType` | `ProcessType` | `"Standard"`, `"Background"`, `"Adaptive"` |
| `TimeOut` | `TimeOut` | Graceful shutdown timeout |
| `ExitTimeOut` | `ExitTimeOut` | Kill timeout after SIGTERM |

Any other keys are passed through as raw launchd plist keys.
