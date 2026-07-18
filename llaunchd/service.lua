-- llaunchd/service.lua
-- Load and manage service definitions from ~/.llaunchd/services/

local M = {}

local HOME = os.getenv("HOME")
local SERVICES_DIR = HOME .. "/.llaunchd/services"
local LAUNCH_AGENTS_DIR = HOME .. "/Library/LaunchAgents"

---Get the services directory path
---@return string
function M.services_dir()
  return SERVICES_DIR
end

---Get the LaunchAgents directory path
---@return string
function M.launch_agents_dir()
  return LAUNCH_AGENTS_DIR
end

---List all .lua service files in ~/.llaunchd/services/
---@return string[] service_names  list of service names (without .lua extension)
function M.list_services()
  local services = {}
  local p = io.popen('ls "' .. SERVICES_DIR .. '"/*.lua 2>/dev/null')
  if p then
    for file in p:lines() do
      local name = file:match("([^/]+)%.lua$")
      if name then
        services[#services+1] = name
      end
    end
    p:close()
  end
  table.sort(services)
  return services
end

---Load a single service definition by name
---@param name string
---@return table|nil config, string|nil error
function M.load_service(name)
  local path = SERVICES_DIR .. "/" .. name .. ".lua"
  local f, err = io.open(path, "r")
  if not f then
    return nil, "service file not found: " .. path
  end
  f:close()

  -- Load and execute the service file
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

---Load all service definitions
---@return table<string, table> services  map of name → config
---@return string[] errors  list of error messages for failed loads
function M.load_all_services()
  local services = {}
  local errors = {}

  for _, name in ipairs(M.list_services()) do
    local config, err = M.load_service(name)
    if config then
      services[name] = config
    else
      errors[#errors+1] = err
    end
  end

  return services, errors
end

---Resolve shorthand fields to full launchd plist keys
---@param config table
---@return table plist_config
function M.resolve_config(config)
  local out = {}

  -- Label is required
  if not config.Label then
    error("service missing required 'Label' field")
  end
  out.Label = config.Label

  -- Program: single string → split into ProgramArguments array
  if config.Program then
    -- Simple split: treat as shell would (split on spaces)
    -- For more complex cases, user should use ProgramArguments directly
    local args = {}
    for word in config.Program:gmatch("%S+") do
      args[#args+1] = word
    end
    out.ProgramArguments = args
  elseif config.ProgramArguments then
    out.ProgramArguments = config.ProgramArguments
  else
    error("service must have either 'Program' or 'ProgramArguments'")
  end

  -- RunAtLoad
  if config.RunAtLoad ~= nil then
    out.RunAtLoad = config.RunAtLoad
  end

  -- Restart → KeepAlive mapping
  if config.Restart then
    local keep_alive = {}
    if config.Restart == "always" then
      keep_alive.SuccessfulExit = true
    elseif config.Restart == "on-failure" then
      keep_alive.Crashed = true
    elseif config.Restart == "never" then
      -- KeepAlive = false (omit or set explicitly)
    else
      error("invalid Restart value: " .. tostring(config.Restart) ..
            " (expected 'always', 'on-failure', or 'never')")
    end

    -- Only set KeepAlive if we have conditions
    if next(keep_alive) then
      out.KeepAlive = keep_alive
    elseif config.Restart == "never" then
      out.KeepAlive = false
    end
  elseif config.KeepAlive ~= nil then
    out.KeepAlive = config.KeepAlive
  end

  -- Standard paths
  if config.StdOut then
    out.StandardOutPath = config.StdOut
  end
  if config.StdErr then
    out.StandardErrorPath = config.StdErr
  end

  -- Environment variables
  if config.Env then
    out.EnvironmentVariables = config.Env
  end

  -- WatchPaths
  if config.WatchPaths then
    out.WatchPaths = config.WatchPaths
  end

  -- WorkingDirectory
  if config.WorkingDirectory then
    out.WorkingDirectory = config.WorkingDirectory
  end

  -- ProcessType
  if config.ProcessType then
    out.ProcessType = config.ProcessType
  end

  -- Resource limits
  if config.SoftResourceLimits then
    out.SoftResourceLimits = config.SoftResourceLimits
  end
  if config.HardResourceLimits then
    out.HardResourceLimits = config.HardResourceLimits
  end

  -- Timeouts
  if config.TimeOut then
    out.TimeOut = config.TimeOut
  end
  if config.ExitTimeOut then
    out.ExitTimeOut = config.ExitTimeOut
  end

  -- Pass through any raw launchd keys we don't explicitly handle
  local reserved = {
    Label=true, Program=true, ProgramArguments=true, RunAtLoad=true,
    KeepAlive=true, StandardOutPath=true, StandardErrorPath=true,
    EnvironmentVariables=true, WatchPaths=true, WorkingDirectory=true,
    ProcessType=true, SoftResourceLimits=true, HardResourceLimits=true,
    TimeOut=true, ExitTimeOut=true, Restart=true,
    StdOut=true, StdErr=true,  -- our aliases, don't pass through
  }
  for k, v in pairs(config) do
    if not reserved[k] then
      out[k] = v
    end
  end

  return out
end

return M
