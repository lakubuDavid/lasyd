-- lasyd.d.lua
-- Type definitions for lasyd service files.
-- Add to your LSP workspace.library for autocomplete on defineAgent {}.
--
-- VS Code: "Lua.workspace.library": ["~/Code/Lua/lasyd/lasyd/lasyd.d.lua"]
-- Neovim:  vim.fn.expand("~/Code/Lua/lasyd/lasyd/lasyd.d.lua")

---@class AgentConfig
---@field Label string                      reverse-DNS identifier (required)
---@field Program string                    command + args as a single string (required)
---@field ProgramArguments? string[]        command as array (alternative to Program)
---@field RunAtLoad? boolean                start at boot (launchd)
---@field Restart? "always"|"on-failure"|"never"  shorthand for KeepAlive/Restart
---@field StdOut? string                    path to stdout log
---@field StdErr? string                    path to stderr log
---@field Env? table<string, string>        environment variables
---@field WorkingDirectory? string          working directory
---@field WatchPaths? string[]              restart on path changes (launchd)
---@field ProcessType? "Standard"|"Background"|"Adaptive"  (launchd)
---@field SoftResourceLimits? table         soft rlimits (launchd)
---@field HardResourceLimits? table         hard rlimits (launchd)
---@field TimeOut? number                   graceful shutdown timeout (launchd)
---@field ExitTimeOut? number               kill timeout after SIGTERM (launchd)
---@field KeepAlive? boolean|AgentKeepAlive  raw launchd KeepAlive (overrides Restart)
--- systemd-specific fields
---@field Description? string               service description (systemd)
---@field Type? string                      unit type, e.g. "simple"|"oneshot" (systemd)
---@field WantedBy? string                  install target, e.g. "multi-user.target" (systemd)

---@class AgentKeepAlive
---@field SuccessfulExit? boolean
---@field Crashed? boolean
---@field IdleExit? boolean

--- Define a launchd agent configuration.
--- Returns the config unchanged — exists for LSP type checking.
---@param config AgentConfig
---@return AgentConfig
function defineAgent(config) return config end
