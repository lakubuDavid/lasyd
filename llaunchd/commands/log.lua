-- llaunchd/commands/log.lua

local service = require("service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd log <name>\n")
    return 1
  end

  local stdout, stderr = service.log_files(name)
  local log_path = stdout[1] or stderr[1]

  if not log_path then
    io.stderr:write("No StdOut or StdErr configured for " .. name .. "\n")
    return 1
  end

  local f = io.open(log_path, "r")
  if not f then
    io.stderr:write("Log file not found: " .. log_path .. "\n")
    return 1
  end
  f:close()

  io.write("Tailing " .. log_path .. " (Ctrl+C to stop)\n\n")
  local ret = os.execute('tail -f "' .. log_path .. '"')
  return (ret == 0 or ret == true) and 0 or 1
end

return M
