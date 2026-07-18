-- llaunchd/commands/log.lua
-- Tail service log files (StdOut/StdErr)

local service = require("llaunchd.service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd log <name>\n")
    return 1
  end

  local config, err = service.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  -- Determine which log to tail
  local log_path = config.StdOut or config.StdErr

  if not log_path then
    io.stderr:write("No StdOut or StdErr configured for " .. name .. "\n")
    io.stderr:write("Add StdOut or StdErr to your service definition.\n")
    return 1
  end

  -- Check file exists
  local f = io.open(log_path, "r")
  if not f then
    io.stderr:write("Log file not found: " .. log_path .. "\n")
    io.stderr:write("The service may not have written to it yet.\n")
    return 1
  end
  f:close()

  io.write("Tailing " .. log_path .. " (Ctrl+C to stop)\n\n")

  -- Tail the log file
  local ret = os.execute('tail -f "' .. log_path .. '"')
  return (ret == 0 or ret == true) and 0 or 1
end

return M
