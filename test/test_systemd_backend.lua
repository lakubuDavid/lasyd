-- test/test_systemd_backend.lua — systemd tests (skip on macOS)

local test = require("test")
local systemd = require("backends.systemd")

local function is_darwin()
  local p = io.popen("uname -s 2>/dev/null")
  if p then
    local os_name = p:read("*l")
    p:close()
    return os_name == "Darwin"
  end
  return false
end

local on_macos = is_darwin()

test.group("systemd.name", function()
  if on_macos then
    io.write("  SKIP (macOS)\n")
    return
  end
  test.equal(systemd.name, "systemd", "backend name")
end)

test.group("systemd.resolve_config", function()
  if on_macos then
    io.write("  SKIP (macOS)\n")
    return
  end
  local cfg = systemd.resolve_config({
    Label = "com.test.one",
    Program = "/usr/bin/echo hello",
  })
  test.equal(cfg.Service.ExecStart, "/usr/bin/echo hello", "ExecStart")
  test.equal(cfg.Service.Type, "simple", "default Type")
  test.equal(cfg.Install.WantedBy, "multi-user.target", "default WantedBy")
  test.equal(cfg.Unit.Description, "com.test.one", "default Description")
end)

test.group("systemd.resolve_config options", function()
  if on_macos then
    io.write("  SKIP (macOS)\n")
    return
  end
  local cfg = systemd.resolve_config({
    Label = "com.test.opts",
    Program = "/usr/bin/true",
    Restart = "always",
    WorkingDirectory = "/tmp",
    Env = { PATH = "/usr/bin", HOME = "/root" },
    Type = "oneshot",
    WantedBy = "default.target",
    Description = "My test service",
  })
  test.equal(cfg.Service.Restart, "always", "Restart")
  test.equal(cfg.Service.WorkingDirectory, "/tmp", "WorkingDirectory")
  test.equal(cfg.Service.Type, "oneshot", "Type override")
  test.equal(cfg.Install.WantedBy, "default.target", "WantedBy override")
  test.equal(cfg.Unit.Description, "My test service", "Description override")
  test.ok(#cfg.Service.Environment == 2, "env has 2 entries")
end)

test.group("systemd.resolve_config errors", function()
  if on_macos then
    io.write("  SKIP (macOS)\n")
    return
  end
  test.raises(function()
    systemd.resolve_config({ Program = "/usr/bin/true" })
  end, "missing Label")
  test.raises(function()
    systemd.resolve_config({ Label = "com.test.no" })
  end, "missing Program")
end)

test.group("systemd.to_unit_file", function()
  if on_macos then
    io.write("  SKIP (macOS)\n")
    return
  end
  local unit = systemd.resolve_config({
    Label = "com.test.unit",
    Program = "/usr/bin/echo hi",
    Restart = "on-failure",
  })
  local content = systemd.to_unit_file(unit)
  test.contains(content, "[Unit]", "has [Unit]")
  test.contains(content, "[Service]", "has [Service]")
  test.contains(content, "[Install]", "has [Install]")
  test.contains(content, "ExecStart=/usr/bin/echo hi", "ExecStart line")
  test.contains(content, "Restart=on-failure", "Restart line")
  test.contains(content, "WantedBy=multi-user.target", "WantedBy line")
end)
