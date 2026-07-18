-- llaunchd/commands/install.lua
-- Generate plist files from service definitions → ~/Library/LaunchAgents/

local service = require("llaunchd.service")
local plist = require("llaunchd.plist")

local M = {}

---@param name string|nil  service name, or nil to install all
---@return number exit_code
function M.run(name)
  local to_install = {}

  if name then
    to_install = { name }
  else
    to_install = service.list_services()
    if #to_install == 0 then
      io.write("No services to install.\n")
      return 0
    end
  end

  -- Ensure LaunchAgents directory exists
  local agents_dir = service.launch_agents_dir()
  os.execute('mkdir -p "' .. agents_dir .. '"')

  local installed = 0
  local failed = 0

  for _, svc_name in ipairs(to_install) do
    local config, err = service.load_service(svc_name)
    if not config then
      io.stderr:write("SKIP " .. svc_name .. ": " .. (err or "unknown") .. "\n")
      failed = failed + 1
    else
      local resolved = service.resolve_config(config)
      local label = resolved.Label or svc_name
      local plist_path = agents_dir .. "/" .. label .. ".plist"

      local plist_content = plist.to_plist(resolved)
      local f, werr = io.open(plist_path, "w")
      if not f then
        io.stderr:write("FAIL " .. svc_name .. ": cannot write " .. plist_path .. ": " .. (werr or "") .. "\n")
        failed = failed + 1
      else
        f:write(plist_content)
        f:close()
        io.write("OK   " .. svc_name .. " → " .. plist_path .. "\n")
        installed = installed + 1
      end
    end
  end

  io.write(string.format("\nInstalled: %d  Failed: %d\n", installed, failed))
  return failed > 0 and 1 or 0
end

return M
