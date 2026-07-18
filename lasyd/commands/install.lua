-- lasyd/commands/install.lua

local service = require("service")
local log = require("log")

local M = {}

---@param name string|nil  service name, or nil to install all
---@return number exit_code
function M.run(name)
  local flags = pcall(require, "lasyd_flags") and require("lasyd_flags") or {}
  local dry_run = flags.dry_run

  local to_install = {}

  if name then
    to_install = { name }
  else
    to_install = service.list_services()
    if #to_install == 0 then
      io.write("No services to install.\n")
      return 0
    end
  end

  if dry_run then
    io.write("--dry-run: showing generated unit files, not writing to disk\n\n")
  end

  local installed = 0
  local failed = 0

  for _, svc_name in ipairs(to_install) do
    local backend = service.get_backend()
    local config, err = backend.load_service(svc_name)
    if not config then
      local msg = svc_name .. ": " .. (err or "unknown")
      io.stderr:write("FAIL " .. msg .. "\n")
      log.error("install failed " .. msg)
      failed = failed + 1
    else
      if dry_run then
        -- Show what would be generated
        local resolved = backend.resolve_config(config)
        io.write("=== " .. svc_name .. " ===\n")
        if backend.name == "launchd" then
          local plist = require("plist")
          io.write(plist.to_plist(resolved))
        elseif backend.name == "systemd" then
          local systemd = require("backends.systemd")
          io.write(systemd.to_unit_file(resolved))
        end
        io.write("\n")
        installed = installed + 1
      else
        local ok, ierr = backend.install_unit(svc_name, config)
        if ok then
          io.write("OK   " .. svc_name .. "\n")
          log.info("installed " .. svc_name)
          installed = installed + 1
        else
          local msg = svc_name .. ": " .. (ierr or "unknown")
          io.stderr:write("FAIL " .. msg .. "\n")
          log.error("install failed " .. msg)
          failed = failed + 1
        end
      end
    end
  end

  io.write(string.format("\nInstalled: %d  Failed: %d\n", installed, failed))
  return failed > 0 and 1 or 0
end

return M
