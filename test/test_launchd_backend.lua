-- test/test_launchd_backend.lua — tests for launchd backend

local test = require("test")
local launchd = require("backends.launchd")

test.group("launchd.name", function()
  test.equal(launchd.name, "launchd", "backend name")
end)

test.group("launchd.resolve_config", function()
  -- basic Program string
  local cfg = launchd.resolve_config({
    Label = "com.test.one",
    Program = "/usr/bin/echo hello",
  })
  test.equal(cfg.Label, "com.test.one", "label")
  test.equal(cfg.ProgramArguments[1], "/usr/bin/echo", "first arg")
  test.equal(cfg.ProgramArguments[2], "hello", "second arg")

  -- ProgramArguments array
  cfg = launchd.resolve_config({
    Label = "com.test.two",
    ProgramArguments = { "/usr/bin/echo", "world" },
  })
  test.equal(cfg.ProgramArguments[1], "/usr/bin/echo", "array arg")

  -- Restart "on-failure" → KeepAlive.Crashed
  cfg = launchd.resolve_config({
    Label = "com.test.crash",
    Program = "/usr/bin/true",
    Restart = "on-failure",
  })
  test.equal(cfg.KeepAlive.Crashed, true, "on-failure sets Crashed")

  -- Restart "always" → KeepAlive.SuccessfulExit
  cfg = launchd.resolve_config({
    Label = "com.test.always",
    Program = "/usr/bin/true",
    Restart = "always",
  })
  test.equal(cfg.KeepAlive.SuccessfulExit, true, "always sets SuccessfulExit")

  -- StdOut → StandardOutPath
  cfg = launchd.resolve_config({
    Label = "com.test.log",
    Program = "/usr/bin/true",
    StdOut = "/tmp/out.log",
  })
  test.equal(cfg.StandardOutPath, "/tmp/out.log", "StdOut mapping")
  test.equal(cfg.StdOut, nil, "StdOut removed from output")

  -- unknown keys pass through
  cfg = launchd.resolve_config({
    Label = "com.test.pass",
    Program = "/usr/bin/true",
    CustomKey = "custom_value",
  })
  test.equal(cfg.CustomKey, "custom_value", "pass-through")
end)

test.group("launchd.resolve_config errors", function()
  test.raises(function()
    launchd.resolve_config({ Program = "/usr/bin/true" })
  end, "missing Label")

  test.raises(function()
    launchd.resolve_config({ Label = "com.test.no" })
  end, "missing Program")

  test.raises(function()
    launchd.resolve_config({
      Label = "com.test.bad",
      Program = "/usr/bin/true",
      Restart = "invalid",
    })
  end, "invalid Restart")
end)
