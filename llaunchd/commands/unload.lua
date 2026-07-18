-- llaunchd/commands/unload.lua

local service = require("service")

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
    return 0
  else
    io.stderr:write("Failed to unload " .. name .. ": " .. (err or "unknown") .. "\n")
    return 1
  end
end

return M
