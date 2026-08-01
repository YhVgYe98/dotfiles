-- 纯 Lua 测试运行器: luajit tests/run.lua (在 md-agenda 根目录或任意 cwd)
local script_dir = arg[0]:match("^(.*)/tests/[^/]*$") or "."
package.path = script_dir .. "/lua/?.lua;" .. script_dir .. "/lua/?/init.lua;" .. package.path

passed, failed = 0, 0
failures = {}

function repr(v)
  if type(v) == "table" then
    local keys = {}
    for k in pairs(v) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do
      table.insert(parts, tostring(k) .. "=" .. repr(v[k]))
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return tostring(v)
end

function eq(a, b, msg)
  msg = msg or ""
  if type(a) ~= type(b) then
    error(msg .. ": type mismatch expected " .. repr(a) .. " got " .. repr(b))
  end
  if type(a) == "table" then
    if repr(a) ~= repr(b) then
      error(msg .. "\n  expected " .. repr(a) .. "\n  got      " .. repr(b))
    end
    return
  end
  if a ~= b then
    error(msg .. ": expected " .. repr(a) .. " got " .. repr(b))
  end
end

function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
  else
    failed = failed + 1
    table.insert(failures, "FAIL " .. name .. "\n  " .. tostring(err))
  end
end

-- 加载测试套件
require("tests.test_date")
require("tests.test_calendar")

print(string.format("passed: %d  failed: %d", passed, failed))
if #failures > 0 then
  print("")
  for _, f in ipairs(failures) do
    print(f)
  end
  os.exit(1)
end
