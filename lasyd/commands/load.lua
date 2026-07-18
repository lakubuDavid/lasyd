-- lasyd/commands/load.lua

local service = require("service")
local log = require("log")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: lasyd load <name>\n")
    return 1
  end

  io.write("Loading " .. name .. " ...\n")
  local ok, err = service.load_unit(name)
  if ok then
    io.write("Loaded " .. name .. "\n")
    log.info("loaded " .. name)
    return 0
  else
    local msg = name .. ": " .. (err or "unknown")
    io.stderr:write("Failed to load " .. msg .. "\n")
    log.error("load failed " .. msg)
    return 1
  end
end

return M
