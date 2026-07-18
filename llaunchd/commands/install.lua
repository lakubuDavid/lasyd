-- llaunchd/commands/install.lua

local service = require("service")
local log = require("log")

local M = {}

---@param name string|nil  service name, or nil to install all
---@return number exit_code
function M.run(name)
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

  local installed = 0
  local failed = 0

  for _, svc_name in ipairs(to_install) do
    local ok, err = service.install_unit(svc_name)
    if ok then
      io.write("OK   " .. svc_name .. "\n")
      log.info("installed " .. svc_name)
      installed = installed + 1
    else
      local msg = svc_name .. ": " .. (err or "unknown")
      io.stderr:write("FAIL " .. msg .. "\n")
      log.error("install failed " .. msg)
      failed = failed + 1
    end
  end

  io.write(string.format("\nInstalled: %d  Failed: %d\n", installed, failed))
  return failed > 0 and 1 or 0
end

return M
