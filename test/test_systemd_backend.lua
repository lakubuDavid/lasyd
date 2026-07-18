-- test/test_systemd_backend.lua — stub tests (should fail until implemented on Linux)

local test = require("test")

test.group("systemd stub", function()
  local ok, err = pcall(require, "backends.systemd")
  test.ok(ok, "systemd module loads")

  if ok then
    local systemd = err  -- pcall returns module as second value on success
    test.equal(systemd.name, "systemd", "backend name")

    -- All methods should error with "not implemented yet"
    local methods = {
      {"list_services"},
      {"load_service", "test"},
      {"resolve_config", {Label="x", Program="/bin/true"}},
      {"install_unit", "test", {Label="x"}},
      {"uninstall_unit", "test", {Label="x"}},
      {"load_unit", "test", {Label="x"}},
      {"unload_unit", "test", {Label="x"}},
      {"unit_status", "test", {Label="x"}},
      {"log_files", "test", {Label="x"}},
    }
    for _, m in ipairs(methods) do
      local fn_name = table.remove(m, 1)
      local fn = systemd[fn_name]
      test.ok(type(fn) == "function", fn_name .. " exists")
      test.raises(function() fn(table.unpack(m)) end, fn_name .. " should fail (stub)")
    end
  end
end)
