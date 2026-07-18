# lasyd

Lua-powered service manager for macOS (launchd) and Linux (systemd).

Write service definitions as Lua tables, get native init system units.

## Install

```bash
# Already symlinked at ~/usr/local/bin/lasyd
# Or manually:
ln -s ~/Code/Lua/lasyd/bin/lasyd ~/usr/lcoal/bin/lasyd
```

## Usage

```
lasyd list                  # List all services
lasyd status <name>         # Show service status
lasyd install [name]        # Generate unit file (all or one)
lasyd load <name>           # Load into init system
lasyd unload <name>         # Unload from init system
lasyd log <name>            # Tail log file
lasyd help                  # Show help
```

## Service Files

Place `.lua` files in `~/.lasyd/services/`:

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

Override with env: `LASYD_BACKEND=systemd lasyd list`

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
{ "Lua.workspace.library": ["~/Code/Lua/lasyd/lasyd/lasyd.d.lua"] }
```

## Testing

```bash
lua test/run.lua
```

## Project Structure

```
bin/lasyd              # CLI entry point
lasyd/
├── init.lua              # Core exports
├── backend.lua           # Backend interface contract
├── backends/
│   ├── launchd.lua       # macOS implementation
│   └── systemd.lua       # Linux implementation
├── service.lua           # Service file loader + backend delegation
├── plist.lua             # XML plist serializer
├── lasyd.d.lua        # LSP type defs
└── commands/             # CLI subcommands
test/
├── run.lua               # Test runner
├── test.lua              # Minimal test framework
└── test_*.lua            # Test files
```
