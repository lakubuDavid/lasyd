-- llaunchd/service.lua
-- Backend-agnostic service manager — delegates to the active backend.

local backend_mod = require("backend")

local M = {}

-- Active backend (set by init or CLI)
---@type Backend|nil
M.backend = nil

--- Initialize with a backend name
---@param name string  "launchd" or "systemd"
function M.init(name)
  M.backend = backend_mod.load(name)
end

--- Get the active backend (auto-init if needed)
---@return Backend
function M.get_backend()
  if not M.backend then
    M.init(M.detect())
  end
  return M.backend
end

--- Detect platform: Darwin → launchd, Linux → systemd
---@return string
function M.detect()
  local handle = io.popen("uname -s 2>/dev/null")
  if handle then
    local os_name = handle:read("*l")
    handle:close()
    if os_name == "Darwin" then
      return "launchd"
    elseif os_name == "Linux" then
      return "systemd"
    end
  end
  -- fallback
  return "launchd"
end

--- Delegate methods to backend

---@return string
function M.services_dir()
  return M.get_backend().services_dir()
end

---@return string
function M.init_dir()
  return M.get_backend().init_dir()
end

---@return string[]
function M.list_services()
  return M.get_backend().list_services()
end

---@param name string
---@return table|nil, string|nil
function M.load_service(name)
  return M.get_backend().load_service(name)
end

---@param config table
---@return table
function M.resolve_config(config)
  return M.get_backend().resolve_config(config)
end

---@param name string
---@return boolean, string|nil
function M.install_unit(name)
  local backend = M.get_backend()
  local config, err = backend.load_service(name)
  if not config then
    return false, err
  end
  return backend.install_unit(name, config)
end

---@param name string
---@return boolean, string|nil
function M.uninstall_unit(name)
  local backend = M.get_backend()
  local config, err = backend.load_service(name)
  if not config then
    return false, err
  end
  return backend.uninstall_unit(name, config)
end

---@param name string
---@return boolean, string|nil
function M.load_unit(name)
  local backend = M.get_backend()
  local config, err = backend.load_service(name)
  if not config then
    return false, err
  end
  return backend.load_unit(name, config)
end

---@param name string
---@return boolean, string|nil
function M.unload_unit(name)
  local backend = M.get_backend()
  local config, err = backend.load_service(name)
  if not config then
    return false, err
  end
  return backend.unload_unit(name, config)
end

---@param name string
---@return table
function M.unit_status(name)
  local backend = M.get_backend()
  local config = backend.load_service(name)
  if not config then
    return { Label = name, installed = false, loaded = false }
  end
  return backend.unit_status(name, config)
end

---@param name string
---@return string[], string[]
function M.log_files(name)
  local backend = M.get_backend()
  local config = backend.load_service(name)
  if not config then
    return {}, {}
  end
  return backend.log_files(name, config)
end

return M
