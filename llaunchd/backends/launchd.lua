-- llaunchd/backends/launchd.lua
-- launchd backend for macOS

local plist = require("plist")

local M = {}
M.name = "launchd"

local HOME = os.getenv("HOME")

---@return string
function M.services_dir()
  return HOME .. "/.llaunchd/services"
end

---@return string
function M.init_dir()
  return HOME .. "/Library/LaunchAgents"
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

--- Check if Program uses a bare command name (no leading /)
---@param config table
---@return boolean ok, string|nil error
function M.validate_program(config)
  local program = config.Program
  if not program then return true, nil end

  -- Extract just the command name (first word)
  local cmd = program:match("^(%S+)")
  if not cmd then return true, nil end

  -- If it starts with / or ./ or ../, it's a path — OK
  if cmd:match("^%./") or cmd:match("^%../") or cmd:match("^/") then
    return true, nil
  end

  -- Check if user set PATH in Env
  local has_path = config.Env and config.Env.PATH
  if has_path then
    return true, nil
  end

  return false, string.format(
    "bare command '%s' not found in launchd PATH (use absolute path or set Env.PATH, or pass --unsafe-relative-path)",
    cmd
  )
end

--- Resolve shorthand fields to native launchd plist keys
---@param config table
---@return table
function M.resolve_config(config)
  local out = {}

  if not config.Label then
    error("service missing required 'Label' field")
  end
  out.Label = config.Label

  if config.Program then
    if type(config.Program) == "table" then
      -- Program is already an array
      out.ProgramArguments = config.Program
    else
      -- Program is a string, split on whitespace
      local args = {}
      for word in config.Program:gmatch("%S+") do
        args[#args + 1] = word
      end
      out.ProgramArguments = args
    end
  elseif config.ProgramArguments then
    out.ProgramArguments = config.ProgramArguments
  else
    error("service must have either 'Program' or 'ProgramArguments'")
  end

  if config.RunAtLoad ~= nil then
    out.RunAtLoad = config.RunAtLoad
  end

  if config.Restart then
    if config.Restart == "always" then
      out.KeepAlive = true
    elseif config.Restart == "on-failure" then
      out.KeepAlive = { SuccessfulExit = false }
    elseif config.Restart == "never" then
      out.KeepAlive = false
    else
      error("invalid Restart value: " .. tostring(config.Restart))
    end
  elseif config.KeepAlive ~= nil then
    out.KeepAlive = config.KeepAlive
  end

  if config.StdOut then out.StandardOutPath = config.StdOut end
  if config.StdErr then out.StandardErrorPath = config.StdErr end
  if config.Env then out.EnvironmentVariables = config.Env end
  if config.WatchPaths then out.WatchPaths = config.WatchPaths end
  if config.WorkingDirectory then out.WorkingDirectory = config.WorkingDirectory end
  if config.ProcessType then out.ProcessType = config.ProcessType end
  if config.SoftResourceLimits then out.SoftResourceLimits = config.SoftResourceLimits end
  if config.HardResourceLimits then out.HardResourceLimits = config.HardResourceLimits end
  if config.TimeOut then out.TimeOut = config.TimeOut end
  if config.ExitTimeOut then out.ExitTimeOut = config.ExitTimeOut end

  -- Pass through unknown keys
  local reserved = {
    Label=true, Program=true, ProgramArguments=true, RunAtLoad=true,
    KeepAlive=true, StandardOutPath=true, StandardErrorPath=true,
    EnvironmentVariables=true, WatchPaths=true, WorkingDirectory=true,
    ProcessType=true, SoftResourceLimits=true, HardResourceLimits=true,
    TimeOut=true, ExitTimeOut=true, Restart=true,
    StdOut=true, StdErr=true, Env=true,
  }
  for k, v in pairs(config) do
    if not reserved[k] then
      out[k] = v
    end
  end

  return out
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.install_unit(name, config)
  local resolved = M.resolve_config(config)
  local label = resolved.Label or name
  local dir = M.init_dir()
  os.execute('mkdir -p "' .. dir .. '"')
  local path = dir .. "/" .. label .. ".plist"

  local xml = plist.to_plist(resolved)
  local f, err = io.open(path, "w")
  if not f then
    return false, "cannot write " .. path .. ": " .. (err or "")
  end
  f:write(xml)
  f:close()
  return true, nil
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.uninstall_unit(name, config)
  local label = config.Label or name
  local path = M.init_dir() .. "/" .. label .. ".plist"
  local ok, err = os.remove(path)
  return ok, err
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.load_unit(name, config)
  local label = config.Label or name
  local path = M.init_dir() .. "/" .. label .. ".plist"
  local f = io.open(path, "r")
  if not f then
    return false, "plist not installed: " .. path
  end
  f:close()
  local ret = os.execute('launchctl load "' .. path .. '"')
  if ret == 0 or ret == true then
    return true, nil
  else
    return false, "launchctl load failed"
  end
end

---@param name string
---@param config table
---@return boolean ok, string|nil error
function M.unload_unit(name, config)
  local label = config.Label or name
  local path = M.init_dir() .. "/" .. label .. ".plist"
  local ret = os.execute('launchctl unload "' .. path .. '"')
  if ret == 0 or ret == true then
    return true, nil
  else
    return false, "launchctl unload failed"
  end
end

---@param name string
---@param config table
---@return table status
function M.unit_status(name, config)
  if not config then
    return { Label = name, installed = false, loaded = false }
  end
  local label = config.Label or name
  local plist_path = M.init_dir() .. "/" .. label .. ".plist"

  local installed = false
  local f = io.open(plist_path, "r")
  if f then
    f:close()
    installed = true
  end

  local loaded = false
  local p = io.popen('launchctl list 2>/dev/null | grep "' .. label .. '"')
  if p then
    local line = p:read("*l")
    p:close()
    loaded = line ~= nil and line:match("%S") ~= nil
  end

  return {
    Label = label,
    installed = installed,
    plist_path = plist_path,
    loaded = loaded,
  }
end

---@param name string
---@param config table
---@return string[] stdout, string[] stderr
function M.log_files(name, config)
  local stdout = {}
  local stderr = {}
  if config.StdOut then stdout[#stdout + 1] = config.StdOut end
  if config.StandardOutPath then stdout[#stdout + 1] = config.StandardOutPath end
  if config.StdErr then stderr[#stderr + 1] = config.StdErr end
  if config.StandardErrorPath then stderr[#stderr + 1] = config.StandardErrorPath end
  return stdout, stderr
end

return M
