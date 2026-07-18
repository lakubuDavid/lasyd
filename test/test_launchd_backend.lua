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

  -- Restart "on-failure" → KeepAlive = {SuccessfulExit=false}
  cfg = launchd.resolve_config({
    Label = "com.test.crash",
    Program = "/usr/bin/true",
    Restart = "on-failure",
  })
  test.equal(cfg.KeepAlive.SuccessfulExit, false, "on-failure sets SuccessfulExit=false")

  -- Restart "always" → KeepAlive = true
  cfg = launchd.resolve_config({
    Label = "com.test.always",
    Program = "/usr/bin/true",
    Restart = "always",
  })
  test.equal(cfg.KeepAlive, true, "always sets KeepAlive=true")

  -- Restart "never" → KeepAlive = false
  cfg = launchd.resolve_config({
    Label = "com.test.never",
    Program = "/usr/bin/true",
    Restart = "never",
  })
  test.equal(cfg.KeepAlive, false, "never sets KeepAlive=false")

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

test.group("launchd.validate_program", function()
  -- absolute path: OK
  local ok = launchd.validate_program({ Program = "/usr/bin/echo hi" })
  test.ok(ok, "absolute path passes")

  -- relative ./path: OK
  ok = launchd.validate_program({ Program = "./mytool" })
  test.ok(ok, "relative ./path passes")

  -- bare command with Env.PATH: OK
  ok = launchd.validate_program({ Program = "echo hi", Env = { PATH = "/usr/bin" } })
  test.ok(ok, "bare command with PATH passes")

  -- bare command no PATH: FAIL
  local pass, err = launchd.validate_program({ Program = "echo hi" })
  test.equal(pass, false, "bare command without PATH fails")
  test.ok(err:find("bare command"), "error mentions bare command")
end)

test.group("launchd.resolve_config Program as table", function()
  -- Program as table
  local cfg = launchd.resolve_config({
    Label = "com.test.table",
    Program = { "/usr/bin/mytool", "--flag", "arg with space" },
  })
  test.equal(cfg.ProgramArguments[1], "/usr/bin/mytool", "first arg")
  test.equal(cfg.ProgramArguments[2], "--flag", "second arg")
  test.equal(cfg.ProgramArguments[3], "arg with space", "arg with space preserved")

  -- Program as string (existing behavior)
  cfg = launchd.resolve_config({
    Label = "com.test.string",
    Program = "/usr/bin/echo hello",
  })
  test.equal(cfg.ProgramArguments[1], "/usr/bin/echo", "string split first")
  test.equal(cfg.ProgramArguments[2], "hello", "string split second")
end)
