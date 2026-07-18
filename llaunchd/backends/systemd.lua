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
  local services = {}
  local p = io.popen('ls "' .. M.services_dir() .. '"/*.lua 2>/dev/null')
  if p then
    for file in p:lines() do
      local name = file:match("([^/]+)%.lua$")
      if name then
        services[#services + 1] = name
      end
    end
    p:close()
  end
  table.sort(services)
  return services
end

---@param name string
---@return table|nil config, string|nil error
function M.load_service(name)
  local path = M.services_dir() .. "/" .. name .. ".lua"
  local f, err = io.open(path, "r")
  if not f then
    return nil, "service file not found: " .. path
  end
  f:close()

  local chunk, load_err = loadfile(path)
  if not chunk then
    return nil, "syntax error in " .. name .. ".lua: " .. (load_err or "unknown")
  end

  local ok, result = pcall(chunk)
  if not ok then
    return nil, "runtime error in " .. name .. ".lua: " .. tostring(result)
  end

  if type(result) ~= "table" then
    return nil, name .. ".lua must return a table (got " .. type(result) .. ")"
  end

  return result, nil
end

--- Translate llaunchd config to systemd unit format
---@param config table
---@return table
function M.resolve_config(config)
  if not config.Label then
    error("service missing required 'Label' field")
  end

  if not config.Program then
    error("service must have 'Program' (maps to ExecStart)")
  end

  -- Build systemd [Service] and [Unit] sections
  local unit = {}
  local service = {}
  local install = {}

  -- [Unit]
  unit.Description = config.Description or config.Label

  -- [Service]
  service.ExecStart = config.Program
  service.Type = config.Type or "simple"

  if config.Restart then
    service.Restart = config.Restart
  end

  if config.WorkingDirectory then
    service.WorkingDirectory = config.WorkingDirectory
  end

  if config.Env then
    local env_lines = {}
    for k, v in pairs(config.Env) do
      env_lines[#env_lines + 1] = k .. "=" .. v
    end
    service.Environment = env_lines
  end

  -- [Install]
  install.WantedBy = config.WantedBy or "multi-user.target"

  return {
    Unit = unit,
    Service = service,
    Install = install,
  }
end

--- Serialize to systemd unit file format
---@param config table  resolved config with Unit/Service/Install
---@return string
function M.to_unit_file(config)
  local lines = {}

  -- [Unit]
  if config.Unit then
    lines[#lines + 1] = "[Unit]"
    for k, v in pairs(config.Unit) do
      lines[#lines + 1] = k .. "=" .. tostring(v)
    end
    lines[#lines + 1] = ""
  end

  -- [Service]
  if config.Service then
    lines[#lines + 1] = "[Service]"
    for k, v in pairs(config.Service) do
      if type(v) == "table" then
        for _, item in ipairs(v) do
          lines[#lines + 1] = k .. "=" .. tostring(item)
        end
      else
        lines[#lines + 1] = k .. "=" .. tostring(v)
      end
    end
    lines[#lines + 1] = ""
  end

  -- [Install]
  if config.Install then
    lines[#lines + 1] = "[Install]"
    for k, v in pairs(config.Install) do
      lines[#lines + 1] = k .. "=" .. tostring(v)
    end
  end

  return table.concat(lines, "\n") .. "\n"
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.install_unit(name, config)
  local resolved = M.resolve_config(config)
  local unit_name = config.Label or (name .. ".service")
  if not unit_name:match("%.service$") then
    unit_name = unit_name .. ".service"
  end

  local dir = M.init_dir()
  os.execute('mkdir -p "' .. dir .. '"')
  local path = dir .. "/" .. unit_name

  local content = M.to_unit_file(resolved)
  local f, err = io.open(path, "w")
  if not f then
    return false, "cannot write " .. path .. ": " .. (err or "")
  end
  f:write(content)
  f:close()

  os.execute("systemctl daemon-reload")
  return true, nil
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.uninstall_unit(name, config)
  local unit_name = config.Label or (name .. ".service")
  if not unit_name:match("%.service$") then
    unit_name = unit_name .. ".service"
  end
  local path = M.init_dir() .. "/" .. unit_name
  local ok, err = os.remove(path)
  if ok then
    os.execute("systemctl daemon-reload")
  end
  return ok, err
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.load_unit(name, config)
  local unit_name = config.Label or (name .. ".service")
  if not unit_name:match("%.service$") then
    unit_name = unit_name .. ".service"
  end
  local ret = os.execute('systemctl enable --now "' .. unit_name .. '"')
  if ret == 0 or ret == true then
    return true, nil
  else
    return false, "systemctl enable --now failed"
  end
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.unload_unit(name, config)
  local unit_name = config.Label or (name .. ".service")
  if not unit_name:match("%.service$") then
    unit_name = unit_name .. ".service"
  end
  local ret = os.execute('systemctl disable --now "' .. unit_name .. '"')
  if ret == 0 or ret == true then
    return true, nil
  else
    return false, "systemctl disable --now failed"
  end
end

---@param name string
---@param config table
---@return table status
function M.unit_status(name)
  local unit_name = config.Label or (name .. ".service")
  if not unit_name:match("%.service$") then
    unit_name = unit_name .. ".service"
  end

  local installed = false
  local f = io.open(M.init_dir() .. "/" .. unit_name, "r")
  if f then
    f:close()
    installed = true
  end

  local active = false
  local p = io.popen('systemctl is-active "' .. unit_name .. '" 2>/dev/null')
  if p then
    local line = p:read("*l")
    p:close()
    active = line == "active"
  end

  return {
    Label = unit_name,
    installed = installed,
    loaded = active,
  }
end

---@param name string
---@param config table
---@return string[] stdout, string[] stderr
function M.log_files(name, config)
  local stdout = {}
  local stderr = {}
  if config.StdOut then stdout[#stdout + 1] = config.StdOut end
  if config.StdErr then stderr[#stderr + 1] = config.StdErr end
  return stdout, stderr
end

return M
