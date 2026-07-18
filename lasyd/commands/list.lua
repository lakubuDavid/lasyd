-- lasyd/commands/list.lua

local service = require("service")

local M = {}

function M.run()
  local services = service.list_services()

  if #services == 0 then
    io.write("No services found in " .. service.services_dir() .. "\n")
    return 0
  end

  io.write("Services (" .. #services .. "):\n")
  for _, name in ipairs(services) do
    local config, err = service.load_service(name)
    if config then
      local status = config.RunAtLoad and "enabled" or "disabled"
      local program = config.Program or (config.ProgramArguments and config.ProgramArguments[1]) or "?"
      io.write(string.format("  %-24s %-10s %s\n", name, status, program))
    else
      io.write(string.format("  %-24s %-10s %s\n", name, "error", err or "unknown error"))
    end
  end

  return 0
end

return M
