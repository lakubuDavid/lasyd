-- lasyd/commands/errlog.lua
-- Tail the centralized error log

local log = require("log")

local M = {}

---@return number exit_code
function M.run()
  local path = log.path()
  local f = io.open(path, "r")
  if not f then
    io.write("No error log yet: " .. path .. "\n")
    return 0
  end
  f:close()

  io.write("Tailing " .. path .. " (Ctrl+C to stop)\n\n")
  local ret = os.execute('tail -f "' .. path .. '"')
  return (ret == 0 or ret == true) and 0 or 1
end

return M
