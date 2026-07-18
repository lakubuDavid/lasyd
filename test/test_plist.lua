-- test/test_plist.lua — tests for plist serializer

local test = require("test")
local plist = require("plist")

test.group("plist.to_plist", function()
  local xml = plist.to_plist({ Label = "test" })
  test.contains(xml, '<?xml version="1.0"', "header")
  test.contains(xml, "<plist version=\"1.0\">", "plist tag")
  test.contains(xml, "</plist>", "closing plist")
  test.contains(xml, "<key>Label</key>", "key name")
  test.contains(xml, "<string>test</string>", "string value")
end)

test.group("plist types", function()
  -- string
  local xml = plist.to_plist({ Name = "hello" })
  test.contains(xml, "<string>hello</string>", "string type")

  -- integer
  xml = plist.to_plist({ Port = 8080 })
  test.contains(xml, "<integer>8080</integer>", "integer type")

  -- boolean true
  xml = plist.to_plist({ Enabled = true })
  test.contains(xml, "<true/>", "boolean true")

  -- boolean false
  xml = plist.to_plist({ Enabled = false })
  test.contains(xml, "<false/>", "boolean false")

  -- array
  xml = plist.to_plist({ Args = { "a", "b", "c" } })
  test.contains(xml, "<array>", "array open")
  test.contains(xml, "<string>a</string>", "array item")
  test.contains(xml, "</array>", "array close")

  -- nested dict
  xml = plist.to_plist({ Sub = { Key = "val" } })
  test.contains(xml, "<dict>", "nested dict")
  test.contains(xml, "<key>Key</key>", "nested key")
  test.contains(xml, "<string>val</string>", "nested value")
end)

test.group("plist escaping", function()
  local xml = plist.to_plist({ Name = "a&b<c>d" })
  test.contains(xml, "a&amp;b&lt;c&gt;d", "escapes XML entities")
end)
