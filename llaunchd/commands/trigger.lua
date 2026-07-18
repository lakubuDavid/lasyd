-- llaunchd/commands/trigger.lua
-- Manually trigger a service via launchctl start

local service = require("service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd trigger <name>\n")
    return 1
  end

  local backend = service.get_backend()

  local config, err = backend.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  local label = config.Label or name
  io.write("Triggering " .. label .. " ...\n")

  local ret = os.execute('launchctl start "' .. label .. '"')
  if ret == 0 or ret == true then
    io.write("Triggered " .. label .. "\n")
    return 0
  else
    io.stderr:write("Failed to trigger " .. label .. "\n")
    return 1
  end
end

return M
