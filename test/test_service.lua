-- test/test_service.lua — tests for service module backend detection

local test = require("test")
local service = require("service")

test.group("service.detect", function()
  local backend_name = service.detect()
  test.ok(backend_name == "launchd" or backend_name == "systemd",
    "detect returns launchd or systemd")
end)

test.group("service.init", function()
  service.init("launchd")
  test.equal(service.get_backend().name, "launchd", "init launchd")

  service.init("systemd")
  test.equal(service.get_backend().name, "systemd", "init systemd")

  -- restore to launchd for other tests
  service.init("launchd")
end)
