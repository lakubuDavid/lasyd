-- llaunchd/commands/status.lua
-- Show status of a service via launchctl

local service = require("llaunchd.service")

local M = {}

---Run a shell command and return output
---@param cmd string
---@return string output, number exit_code
local function capture(cmd)
  local p = io.popen(cmd .. " 2>&1")
  if not p then return "", 1 end
  local output = p:read("*a")
  local _, _, code = p:close()
  return output, code or 0
end

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd status <name>\n")
    return 1
  end

  -- Check if service file exists
  local config, err = service.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  local label = config.Label or name
  io.write("Service: " .. name .. "\n")
  io.write("Label:   " .. label .. "\n")

  -- Check if plist is installed
  local plist_path = service.launch_agents_dir() .. "/" .. label .. ".plist"
  local f = io.open(plist_path, "r")
  if f then
    f:close()
    io.write("Plist:   installed (" .. plist_path .. ")\n")
  else
    io.write("Plist:   NOT installed (run: llaunchd install " .. name .. ")\n")
  end

  -- Check launchctl status
  local output, code = capture("launchctl list | grep " .. label)
  if code == 0 and output:match("%S") then
    io.write("launchctl:\n")
    for line in output:gmatch("[^\n]+") do
      io.write("  " .. line .. "\n")
    end
  else
    io.write("Status:  not loaded in launchctl\n")
  end

  -- Check for log files
  if config.StdOut then
    io.write("StdOut:  " .. config.StdOut .. "\n")
  end
  if config.StdErr then
    io.write("StdErr:  " .. config.StdErr .. "\n")
  end

  return 0
end

return M
