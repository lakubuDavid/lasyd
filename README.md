# llaunchd

Lua-powered service manager for macOS (launchd) and Linux (systemd).

Write service definitions as Lua tables, get native init system units.

## Install

```bash
# Already symlinked at ~/tools/llaunchd
# Or manually:
ln -s ~/Code/Lua/llaunchd/bin/llaunchd ~/tools/llaunchd
```

## Usage

```
llaunchd list                  # List all services
llaunchd status <name>         # Show service status
llaunchd install [name]        # Generate unit file (all or one)
llaunchd load <name>           # Load into init system
llaunchd unload <name>         # Unload from init system
llaunchd log <name>            # Tail log file
llaunchd help                  # Show help
```

## Service Files

Place `.lua` files in `~/.llaunchd/services/`:

```lua
return defineAgent {
    Label   = "com.example.myagent",
    Program = "/usr/local/bin/mytool --flag",
    RunAtLoad = true,
    Restart = "on-failure",
    StdOut  = "/tmp/myagent.log",
    Env     = { PATH = "/usr/local/bin:/usr/bin:/bin" },
}
```

## Backend

Auto-detected: macOS → launchd, Linux → systemd.

Override with env: `LLAUNCHD_BACKEND=systemd llaunchd list`

### launchd (macOS)

| Key | Maps To |
|-----|---------|
| `Label` | `Label` |
| `Program` | `ProgramArguments` (auto-split) |
| `RunAtLoad` | `RunAtLoad` |
| `Restart` | `KeepAlive` shorthand |
| `StdOut` | `StandardOutPath` |
| `StdErr` | `StandardErrorPath` |
| `Env` | `EnvironmentVariables` |

Generated: `~/Library/LaunchAgents/<Label>.plist`

### systemd (Linux)

| Key | Maps To |
|-----|---------|
| `Label` | unit filename |
| `Program` | `ExecStart` |
| `Restart` | `Restart` |
| `WorkingDirectory` | `WorkingDirectory` |
| `Env` | `Environment` |
| `Description` | `[Unit] Description` |
| `WantedBy` | `[Install] WantedBy` |

Generated: `/etc/systemd/system/<Label>.service`

## LSP Type Checking

```json
// .vscode/settings.json
{ "Lua.workspace.library": ["~/Code/Lua/llaunchd/llaunchd/llaunchd.d.lua"] }
```

## Testing

```bash
lua test/run.lua
```

## Project Structure

```
bin/llaunchd              # CLI entry point
llaunchd/
├── init.lua              # Core exports
├── backend.lua           # Backend interface contract
├── backends/
│   ├── launchd.lua       # macOS implementation
│   └── systemd.lua       # Linux implementation
├── service.lua           # Service file loader + backend delegation
├── plist.lua             # XML plist serializer
├── llaunchd.d.lua        # LSP type defs
└── commands/             # CLI subcommands
test/
├── run.lua               # Test runner
├── test.lua              # Minimal test framework
└── test_*.lua            # Test files
```
