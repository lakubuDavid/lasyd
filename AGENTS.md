# AGENTS.md

## Project

`llaunchd` — Lua CLI for managing launchd/systemd services.

## Structure

```
bin/llaunchd              # Entry point (shebang, symlinked to ~/tools/llaunchd)
llaunchd/
├── init.lua              # Core exports
├── backend.lua           # Backend interface contract
├── backends/
│   ├── launchd.lua       # macOS implementation
│   └── systemd.lua       # Linux stub
├── service.lua           # Service file loader
├── plist.lua             # XML plist serializer
├── llaunchd.d.lua        # LSP type defs
└── commands/             # CLI subcommands
```

## Rules

- Always use `defineAgent {}` (no parens) in service file examples
- Backend interface: `services_dir, init_dir, list_services, load_service, resolve_config, install_unit, uninstall_unit, load_unit, unload_unit, unit_status, log_files`
- Run tests via `~/tools/llaunchd <command>` after changes
- Symlink: `~/tools/llaunchd` → `~/Code/Lua/llaunchd/bin/llaunchd`
- Services live in `~/.llaunchd/services/*.lua`
- Generated units go to `~/Library/LaunchAgents/` (launchd) or `/etc/systemd/system/` (systemd)
- Use `todo` CLI (not todo_manager) for task tracking
- Skills go in `~/.agents/skills/llaunchd/` symlinked to `~/.pi/agent/skills/`
