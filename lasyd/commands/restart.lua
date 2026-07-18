-- lasyd/commands/restart.lua
-- Restart a service: unload then load (or daemon-reload + restart on systemd)

local service = require("service")

local M = {}

---@param name string
---@return number exit_code
function M.run(name)
  if not name then
    io.stderr:write("usage: lasyd restart <name>\n")
    return 1
  end

  local backend = service.get_backend()

  local config, err = backend.load_service(name)
  if not config then
    io.stderr:write("error: " .. (err or "unknown") .. "\n")
    return 1
  end

  io.write("Restarting " .. name .. " ...\n")

  local ok, rerr

  if backend.name == "launchd" then
    -- Unload first (ignore error if not loaded)
    backend.unload_unit(name, config)
    -- Then load
    ok, rerr = backend.load_unit(name, config)
  elseif backend.name == "systemd" then
    -- On systemd, we can just restart directly
    local label = config.Label or (name .. ".service")
    if not label:match("%.service$") then
      label = label .. ".service"
    end
    local ret = os.execute('systemctl restart "' .. label .. '"')
    ok = (ret == 0 or ret == true)
    rerr = ok and nil or "systemctl restart failed"
  else
    ok, rerr = false, "unknown backend"
  end

  if ok then
    io.write("Restarted " .. name .. "\n")
    return 0
  else
    io.stderr:write("Failed to restart " .. name .. ": " .. (rerr or "unknown") .. "\n")
    return 1
  end
end

return M
