-- llaunchd/init.lua
-- Core library — exports all public APIs

local M = {}

-- Sub-modules
M.plist   = require("llaunchd.plist")
M.service = require("llaunchd.service")

-- Commands
M.commands = {
  list    = require("llaunchd.commands.list"),
  status  = require("llaunchd.commands.status"),
  install = require("llaunchd.commands.install"),
  load    = require("llaunchd.commands.load"),
  unload  = require("llaunchd.commands.unload"),
  log     = require("llaunchd.commands.log"),
}

---Print usage help
function M.usage()
  io.write([[
llaunchd — launchd services in Lua

Usage:
  llaunchd list                  List all services
  llaunchd status <name>         Show service status
  llaunchd install [name]        Generate plist from service definition
  llaunchd load <name>           Load service into launchctl
  llaunchd unload <name>         Unload service from launchctl
  llaunchd log <name>            Tail service log file
  llaunchd help                  Show this help

Service files live in:
  ]] .. M.service.services_dir() .. [[/*.lua

Each file must return a table via defineAgent {}:
  return defineAgent {
    Label   = "com.example.myagent",
    Program = "/usr/local/bin/mytool --flag",
    RunAtLoad = true,
    Restart = "on-failure",
    StdOut  = "/tmp/myagent.log",
    Env     = { PATH = "/usr/local/bin:/usr/bin:/bin" },
  }
]])
end

return M
