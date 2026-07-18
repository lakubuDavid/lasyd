-- lasyd/backend.lua
-- Backend interface — defines the contract that launchd/systemd backends must implement.

local M = {}

---@class Backend
---@field name string                          "launchd" or "systemd"
---@field services_dir fun(): string            path to service .lua files
---@field init_dir fun(): string                path to generated service files (LaunchAgents / systemd units)
---@field list_services fun(): string[]         list service names from services_dir
---@field load_service fun(name: string): table|nil, string|nil   load and execute a .lua service file
---@field resolve_config fun(config: table): table   translate config to OS-native format
---@field install_unit fun(name: string, config: table): boolean, string|nil   write unit file to init_dir
---@field uninstall_unit fun(name: string, config: table): boolean, string|nil
---@field load_unit fun(name: string, config: table): boolean, string|nil     activate the unit
---@field unload_unit fun(name: string, config: table): boolean, string|nil   deactivate the unit
---@field unit_status fun(name: string, config: table): table    return status info
---@field log_files fun(name: string, config: table): string[], string[]  return {stdout_paths}, {stderr_paths}

--- Validate that a backend table implements all required methods
---@param backend Backend
---@return boolean ok, string|nil error
function M.validate(backend)
  local required = {
    "name", "services_dir", "init_dir", "list_services",
    "load_service", "resolve_config",
    "install_unit", "uninstall_unit",
    "load_unit", "unload_unit",
    "unit_status", "log_files",
  }
  for _, method in ipairs(required) do
    if type(backend[method]) ~= "function" and type(backend[method]) ~= "string" then
      return false, "backend missing method: " .. method
    end
  end
  return true, nil
end

--- Load a backend by name
---@param name string  "launchd" or "systemd"
---@return Backend backend
function M.load(name)
  local ok, backend = pcall(require, "lasyd.backends." .. name)
  if not ok then
    error("failed to load backend '" .. name .. "': " .. tostring(backend))
  end
  local valid, err = M.validate(backend)
  if not valid then
    error("backend '" .. name .. "' is invalid: " .. (err or "unknown"))
  end
  return backend
end

return M
