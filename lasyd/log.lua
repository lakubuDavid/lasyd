-- lasyd/log.lua
-- Centralized error logging to /etc/lasyd/lasyd.error.log

local M = {}

local HOME = os.getenv("HOME")
local LOG_DIR = HOME .. "/.lasyd/logs"
local LOG_FILE = LOG_DIR .. "/lasyd.error.log"

--- Ensure log directory exists
local function ensure_dir()
  os.execute('mkdir -p "' .. LOG_DIR .. '"')
end

--- Append a message to the error log
---@param level string   "ERROR", "WARN", "INFO"
---@param msg string
function M.write(level, msg)
  ensure_dir()
  local ts = os.date("%Y-%m-%d %H:%M:%S")
  local line = string.format("[%s] %s: %s\n", ts, level, msg)
  local f = io.open(LOG_FILE, "a")
  if f then
    f:write(line)
    f:close()
  end
end

---@param msg string
function M.error(msg)
  M.write("ERROR", msg)
end

---@param msg string
function M.warn(msg)
  M.write("WARN", msg)
end

---@param msg string
function M.info(msg)
  M.write("INFO", msg)
end

--- Get the log file path
---@return string
function M.path()
  return LOG_FILE
end

return M
