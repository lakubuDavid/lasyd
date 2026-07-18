-- llaunchd/commands/unload.lua

local service = require("service")
local log = require("log")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd unload <name>\n")
    return 1
  end

  io.write("Unloading " .. name .. " ...\n")
  local ok, err = service.unload_unit(name)
  if ok then
    io.write("Unloaded " .. name .. "\n")
    log.info("unloaded " .. name)
    return 0
  else
    local msg = name .. ": " .. (err or "unknown")
    io.stderr:write("Failed to unload " .. msg .. "\n")
    log.error("unload failed " .. msg)
    return 1
  end
end

return M
