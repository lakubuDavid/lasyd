# lasyd

Lua-powered service manager for macOS (launchd) and Linux (systemd).

Write service definitions as Lua tables. Get native init system units.

## Install

```bash
# Already installed at /usr/local/bin/lasyd
# Or manually:
sudo ln -s ~/Code/Lua/lasyd/bin/lasyd /usr/local/bin/lasyd
```

## Quick Start

```bash
# Create a service
cat > ~/.lasyd/services/myapp.lua << 'EOF'
return defineAgent {
    Label   = "com.example.myapp",
    Program = "/usr/local/bin/myapp --flag",
    RunAtLoad = true,
    Restart = "on-failure",
    StdOut  = "/tmp/myapp.log",
}
EOF

# Install and load
lasyd install myapp
lasyd load myapp
```

## Commands

| Command | Description |
|---------|-------------|
| `lasyd list` | List all services |
| `lasyd status <name>` | Show service status |
| `lasyd install [name]` | Generate unit file (all or one) |
| `lasyd load <name>` | Load into init system |
| `lasyd unload <name>` | Unload from init system |
| `lasyd restart <name>` | Restart service (unload+load) |
| `lasyd trigger <name>` | Manually run service now |
| `lasyd log <name>` | Tail service log |
| `lasyd errlog` | Tail error log |

### Flags

| Flag | Description |
|------|-------------|
| `--dry-run`, `-n` | Show generated unit file without writing |
| `--unsafe-relative-path` | Allow bare command names (e.g. `mytool` instead of `/usr/local/bin/mytool`) |

## Service Files

Place `.lua` files in `~/.lasyd/services/`:

```lua
return defineAgent {
    -- Required
    Label   = "com.example.myagent",          -- reverse-DNS identifier
    Program = "/usr/local/bin/mytool --flag", -- command + args (string, auto-split)

    -- Optional
    RunAtLoad = true,                         -- start at boot
    Restart = "on-failure",                   -- "always" | "on-failure" | "never"
    StdOut  = "/tmp/myagent.log",             -- stdout log file
    StdErr  = "/tmp/myagent.err",             -- stderr log file
    WorkingDirectory = "/tmp",                -- working directory
    Env = { PATH = "/usr/local/bin:/usr/bin:/bin" },
}
```

### Program as Table

For arguments with spaces, use a table instead of a string:

```lua
Program = { "/usr/bin/mytool", "--flag", "arg with space" }
```

### Bare Command Validation

Bare command names (no `/` prefix) will fail unless:
- `Env.PATH` is set in the service, OR
- `--unsafe-relative-path` flag is passed

```bash
# This fails:
lasyd install myapp
# Error: bare command 'mytool' not found in launchd PATH

# This works:
lasyd install myapp --unsafe-relative-path

# Or set PATH in the service:
Env = { PATH = "/usr/local/bin:/usr/bin:/bin" }
```

## Backend

Auto-detected: macOS → launchd, Linux → systemd.

Override: `LASYD_BACKEND=systemd lasyd list`

### launchd (macOS)

| Service Key | Plist Key |
|-------------|-----------|
| `Label` | `Label` |
| `Program` | `ProgramArguments` (auto-split) |
| `RunAtLoad` | `RunAtLoad` |
| `Restart="always"` | `KeepAlive = true` |
| `Restart="on-failure"` | `KeepAlive = {SuccessfulExit=false}` |
| `Restart="never"` | `KeepAlive = false` |
| `StdOut` | `StandardOutPath` |
| `StdErr` | `StandardErrorPath` |
| `Env` | `EnvironmentVariables` |

Generated: `~/Library/LaunchAgents/<Label>.plist`

### systemd (Linux)

| Service Key | Unit Key |
|-------------|----------|
| `Label` | unit filename |
| `Program` | `ExecStart` |
| `Restart` | `Restart` |
| `WorkingDirectory` | `WorkingDirectory` |
| `Env` | `Environment` |
| `Description` | `[Unit] Description` |
| `WantedBy` | `[Install] WantedBy` |

Generated: `/etc/systemd/system/<Label>.service`

## LSP Type Checking

Add `lasyd.d.lua` to your editor for autocomplete:

**VS Code** (`.vscode/settings.json`):
```json
{ "Lua.workspace.library": ["~/Code/Lua/lasyd/lasyd/lasyd.d.lua"] }
```

**Neovim**:
```lua
require('lspconfig').lua_ls.setup {
  settings = { Lua = { workspace = { library = {
    vim.fn.expand("~/Code/Lua/lasyd/lasyd/lasyd.d.lua")
  } } } }
}
```

## Error Logging

Errors log to `~/.lasyd/logs/lasyd.error.log`. Tail with:

```bash
lasyd errlog
```

## Testing

```bash
lua test/run.lua
# or
mise run test
```

## Project Structure

```
bin/lasyd                   # CLI entry point (→ /usr/local/bin/lasyd)
lasyd/
├── init.lua                # Core exports
├── backend.lua             # Backend interface contract
├── backends/
│   ├── launchd.lua         # macOS implementation
│   └── systemd.lua         # Linux implementation
├── service.lua             # Service file loader + backend delegation
├── plist.lua               # XML plist serializer
├── log.lua                 # Error logging
├── lasyd.d.lua             # LSP type defs
└── commands/
    ├── list.lua
    ├── status.lua
    ├── install.lua
    ├── load.lua
    ├── unload.lua
    ├── restart.lua
    ├── trigger.lua
    ├── log.lua
    └── errlog.lua
test/
├── run.lua                 # Test runner
├── test.lua                # Minimal test framework
└── test_*.lua              # Test files
```
