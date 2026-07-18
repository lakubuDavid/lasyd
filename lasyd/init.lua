-- lasyd/init.lua
-- Core library — exports all public APIs

local M = {}

-- Sub-modules
M.plist   = require("plist")
M.service = require("service")
M.backend = require("backend")

-- Commands
M.commands = {
  list    = require("commands.list"),
  status  = require("commands.status"),
  install = require("commands.install"),
  load    = require("commands.load"),
  unload  = require("commands.unload"),
  restart = require("commands.restart"),
  trigger = require("commands.trigger"),
  log     = require("commands.log"),
  errlog  = require("commands.errlog"),
}

---Print usage help
function M.usage()
  local backend_name = M.service.get_backend().name
  io.write(string.format([[
lasyd — launchd/systemd services in Lua (backend: %s)

Usage:
  lasyd list                  List all services
  lasyd status <name>         Show service status
  lasyd install [name]        Generate unit file from service definition
  lasyd load <name>           Load service into init system
  lasyd unload <name>         Unload service from init system
  lasyd restart <name>        Restart service (unload+load)
  lasyd trigger <name>        Manually trigger a service (launchctl start)
  lasyd log <name>            Tail service log file
  lasyd errlog                Tail error log (~/.lasyd/logs/lasyd.error.log)
  lasyd help                  Show this help

Backend:
  %s (%s)

Service files live in:
  %s/*.lua

Each file must return a table via defineAgent {}:
  return defineAgent {
    Label   = "com.example.myagent",
    Program = "/usr/local/bin/mytool --flag",
    RunAtLoad = true,
    Restart = "on-failure",
    StdOut  = "/tmp/myagent.log",
    Env     = { PATH = "/usr/local/bin:/usr/bin:/bin" },
  }
]], backend_name, backend_name, M.service.services_dir(), M.service.services_dir()))
end

return M
