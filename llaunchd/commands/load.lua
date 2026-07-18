-- llaunchd/commands/load.lua
-- Load a service into launchctl

local service = require("llaunchd.service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd load <name>\n")
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

  -- Check plist is installed
  local f = io.open(plist_path, "r")
  if not f then
    io.stderr:write("plist not installed. Run: llaunchd install " .. name .. "\n")
    return 1
  end
  f:close()

  -- Load into launchctl
  io.write("Loading " .. label .. " ...\n")
  local ret = os.execute('launchctl load "' .. plist_path .. '"')
  if ret == 0 or ret == true then
    io.write("Loaded " .. label .. "\n")
    return 0
  else
    io.stderr:write("Failed to load " .. label .. "\n")
    return 1
  end
end

return M
