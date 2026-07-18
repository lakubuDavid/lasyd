-- llaunchd/commands/load.lua

local service = require("service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd load <name>\n")
    return 1
  end

  io.write("Loading " .. name .. " ...\n")
  local ok, err = service.load_unit(name)
  if ok then
    io.write("Loaded " .. name .. "\n")
    return 0
  else
    io.stderr:write("Failed to load " .. name .. ": " .. (err or "unknown") .. "\n")
    return 1
  end
end

return M
