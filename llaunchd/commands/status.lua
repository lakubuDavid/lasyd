-- llaunchd/commands/status.lua

local service = require("service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: llaunchd status <name>\n")
    return 1
  end

  local config, err = service.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  local st = service.unit_status(name)
  io.write("Service: " .. name .. "\n")
  io.write("Label:   " .. (st.Label or config.Label or "?") .. "\n")

  if st.installed then
    if st.plist_path then
      io.write("Plist:   installed (" .. st.plist_path .. ")\n")
    else
      io.write("Unit:    installed\n")
    end
  else
    io.write("Unit:    NOT installed (run: llaunchd install " .. name .. ")\n")
  end

  if st.loaded then
    io.write("Status:  active\n")
  else
    io.write("Status:  not loaded\n")
  end

  local stdout, stderr = service.log_files(name)
  if #stdout > 0 then io.write("StdOut:  " .. stdout[1] .. "\n") end
  if #stderr > 0 then io.write("StdErr:  " .. stderr[1] .. "\n") end

  return 0
end

return M
