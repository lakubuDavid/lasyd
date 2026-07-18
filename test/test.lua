-- test/test.lua — minimal test framework

local M = {
  passed = 0,
  failed = 0,
  errors = {},
  current = nil,
}

--- Assert equality
---@param got any
---@param expected any
---@param msg string|nil
function M.equal(got, expected, msg)
  if got == expected then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    local info = string.format(
      "FAIL %s: expected %s, got %s",
      msg or "(no message)",
      tostring(expected),
      tostring(got)
    )
    M.errors[#M.errors + 1] = info
    io.stderr:write(info .. "\n")
  end
end

--- Assert truthy
---@param val any
---@param msg string|nil
function M.ok(val, msg)
  if val then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    local info = string.format("FAIL %s: expected truthy, got %s", msg or "(no message)", tostring(val))
    M.errors[#M.errors + 1] = info
    io.stderr:write(info .. "\n")
  end
end

--- Assert string contains substring
---@param haystack string
---@param needle string
---@param msg string|nil
function M.contains(haystack, needle, msg)
  if haystack:find(needle, 1, true) then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    local info = string.format(
      "FAIL %s: %q not found in %q",
      msg or "(no message)",
      needle,
      haystack
    )
    M.errors[#M.errors + 1] = info
    io.stderr:write(info .. "\n")
  end
end

--- Assert error is raised
---@param fn function
---@param msg string|nil
function M.raises(fn, msg)
  local ok = pcall(fn)
  if not ok then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    local info = string.format("FAIL %s: expected error, but none raised", msg or "(no message)")
    M.errors[#M.errors + 1] = info
    io.stderr:write(info .. "\n")
  end
end

--- Run a named test group
---@param name string
---@param fn function
function M.group(name, fn)
  M.current = name
  io.write("--- " .. name .. " ---\n")
  fn()
  M.current = nil
end

--- Print summary and exit with code
function M.summary()
  io.write(string.format("\n%d passed, %d failed\n", M.passed, M.failed))
  if M.failed > 0 then
    io.write("\nFailures:\n")
    for _, e in ipairs(M.errors) do
      io.write("  " .. e .. "\n")
    end
    os.exit(1)
  else
    io.write("All tests passed.\n")
    os.exit(0)
  end
end

return M
