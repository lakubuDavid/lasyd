-- lasyd/plist.lua
-- XML plist serializer (Apple Property List 1.0)

local M = {}

local function escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function is_array(t)
  if type(t) ~= "table" then return false end
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n == #t and n > 0
end

local function serialize(v, indent)
  indent = indent or ""
  local t = type(v)

  if t == "string" then
    return indent .. "<string>" .. escape(v) .. "</string>\n"
  elseif t == "number" then
    if math.type and math.type(v) == "integer" then
      return indent .. "<integer>" .. v .. "</integer>\n"
    end
    return indent .. "<real>" .. v .. "</real>\n"
  elseif t == "boolean" then
    return indent .. (v and "<true/>\n" or "<false/>\n")
  elseif t == "table" then
    if is_array(v) then
      local out = indent .. "<array>\n"
      for _, item in ipairs(v) do
        out = out .. serialize(item, indent .. "  ")
      end
      return out .. indent .. "</array>\n"
    else
      local out = indent .. "<dict>\n"
      local keys = {}
      for k in pairs(v) do keys[#keys+1] = k end
      table.sort(keys)
      for _, k in ipairs(keys) do
        out = out .. indent .. "  <key>" .. escape(k) .. "</key>\n"
        out = out .. serialize(v[k], indent .. "  ")
      end
      return out .. indent .. "</dict>\n"
    end
  end
  error("unsupported plist type: " .. t)
end

---Serialize a Lua table to Apple plist XML
---@param t table
---@return string
function M.to_plist(t)
  return [[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
]] .. serialize(t) .. "</plist>\n"
end

return M
