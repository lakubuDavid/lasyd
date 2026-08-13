# lasyd

Lua-powered service manager for macOS (launchd) and Linux (systemd).

> Why?

I was working on some data analysis project, and had to fetch some real time data periodically.
`cron` seems to never work on my device, I have recently started playing with` systemd` on my Debian machine and I don't like XML (plist) so…yeah.

I use a MacBook, I have a Debian home-server and do backend,

Moving configs between the two is annoying, I am trying to use the same tools on all devices more often,
I switched to `mise` for part of my package management where possible to have the same setups on all devices.
I can just move my `mise.toml` file and install my tools like helix, lazigit ,Yazi ,Zellij ,…

This allows me to write service definitions as Lua tables, and get native init system units.

I like Lua, If I can move all my configs to Lua I will, but I can't (yet)

So this is a start.

> Did you use …?

Yes, yes I did AI, I already had my config schema in mind, Lua is a great DDL so I wrote down my ideas, opened pi and started prompting one command at the time.

I started with table -> plist mapping,
then wrapping `launchd`,
then I had the idea of abstracting `launchd` as a backend to later add `systemd`,
pi implemented the `systemd` part, I still need to test it but it works for me for now.

## Install

Install the latest version through the portfolio redirect:

```sh
curl -fsSL https://lakubudavid.me/lasyd/install.sh | sh
```

The installer clones the project into `~/.local/share/lasyd` and symlinks the
launcher into `~/.local/bin/lasyd`. For a local checkout, you can still link it
manually:

```sh
sudo ln -sfn ~/Code/Lua/lasyd/bin/lasyd /usr/local/bin/lasyd
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
