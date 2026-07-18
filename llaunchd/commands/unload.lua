-- llaunchd/commands/unload.lua
-- Unload a service from launchctl

local service = require("llaunchd.service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd unload <name>\n")
    return 1
  end

  -- Check service exists
  local config, err = service.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  local label = config.Label or name
  local plist_path = service.launch_agents_dir() .. "/" .. label .. ".plist"

  -- Unload from launchctl
  io.write("Unloading " .. label .. " ...\n")
  local ret = os.execute('launchctl unload "' .. plist_path .. '"')
  if ret == 0 or ret == true then
    io.write("Unloaded " .. label .. "\n")
    return 0
  else
    io.stderr:write("Failed to unload " .. label .. "\n")
    return 1
  end
end

return M
