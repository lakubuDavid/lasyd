-- llaunchd/backends/systemd.lua
-- systemd backend for Linux (stub — not yet implemented)

local M = {}
M.name = "systemd"

local HOME = os.getenv("HOME")

---@return string
function M.services_dir()
  return HOME .. "/.llaunchd/services"
end

---@return string
function M.init_dir()
  return "/etc/systemd/system"
end

---@return string[]
function M.list_services()
  error("systemd backend not implemented yet")
end

---@param name string
---@return table|nil, string|nil
function M.load_service(name)
  error("systemd backend not implemented yet")
end

---@param config table
---@return table
function M.resolve_config(config)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return boolean, string|nil
function M.install_unit(name, config)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return boolean, string|nil
function M.uninstall_unit(name, config)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return boolean, string|nil
function M.load_unit(name, config)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return boolean, string|nil
function M.unload_unit(name, config)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return table
function M.unit_status(name)
  error("systemd backend not implemented yet")
end

---@param name string
---@param config table
---@return string[], string[]
function M.log_files(name, config)
  error("systemd backend not implemented yet")
end

return M
