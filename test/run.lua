#!/usr/bin/env lua
-- test/run.lua — run all test_*.lua files

local script_dir = arg[0]:match("(.*/)" ) or "./"
local project_root = script_dir .. "../"

package.path = script_dir .. "?.lua;" ..
               project_root .. "lasyd/?.lua;" ..
               project_root .. "lasyd/?/init.lua;" ..
               package.path

local test = require("test")

local p = io.popen('ls "' .. script_dir .. '"test_*.lua 2>/dev/null')
if not p then
  io.stderr:write("No test files found.\n")
  os.exit(1)
end

local files = {}
for f in p:lines() do
  files[#files + 1] = f
end
p:close()

if #files == 0 then
  io.stderr:write("No test files found.\n")
  os.exit(1)
end

table.sort(files)
for _, f in ipairs(files) do
  dofile(f)
end

test.summary()
