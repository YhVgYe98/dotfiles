-- calendar.lua 纯逻辑单元测试
local cal = require("md-agenda.calendar")
test = test
eq = eq

-- build_grid
test("build_grid: 2026-08 周一起始", function()
  local g = cal.build_grid(2026, 8, 1)
  -- 8/1 是周六 → 第 1 行第 6 列
  eq(g[1][6].day, 1)
  eq(g[1][7].day, 2)
  eq(g[1][1], nil)
  eq(g[6][1].day, 31)
  eq(g[5][7].day, 30)
  eq(#g, 6)
end)

test("build_grid: 2026-02 周日起始且 2/1 是周日", function()
  local g = cal.build_grid(2026, 2, 1)
  eq(g[1][7].day, 1)
  eq(g[5][6].day, 28)
  eq(g[6][1], nil)
end)

test("build_grid: 2024-02 闰年 29 天", function()
  local g = cal.build_grid(2024, 2, 1)
  eq(g[1][4].day, 1) -- 2/1 是周四
  eq(g[5][4].day, 29)
  eq(g[5][5], nil)
end)

test("build_grid: 周日起始", function()
  local g = cal.build_grid(2026, 8, 7)
  -- 8/1 是周六, 周日起始 → 第 1 行第 7 列
  eq(g[1][7].day, 1)
  eq(g[1][1], nil)
  -- 第 2 行周日起: 8/2 周日 → 第 2 行第 1 列
  eq(g[2][1].day, 2)
end)

-- step_time
test("step_time: 小时", function()
  local h, m = cal.step_time(10, 0, "hour", 1)
  eq(h, 11)
  eq(m, 0)
  h, m = cal.step_time(23, 30, "hour", 1)
  eq(h, 0)
  eq(m, 30)
  h, m = cal.step_time(0, 30, "hour", -1)
  eq(h, 23)
  eq(m, 30)
end)

test("step_time: 分钟步长 5 对齐后步进", function()
  -- 11 分 → 15 分 (对齐到 5 分钟网格, 而非 +5=16)
  local h, m = cal.step_time(10, 11, "min", 1)
  eq(h, 10)
  eq(m, 15)
  -- 已对齐: 15 → 20
  h, m = cal.step_time(10, 15, "min", 1)
  eq(h, 10)
  eq(m, 20)
  -- 向下: 11 → 10
  h, m = cal.step_time(10, 11, "min", -1)
  eq(h, 10)
  eq(m, 10)
  -- 向下: 已对齐 15 → 10
  h, m = cal.step_time(10, 15, "min", -1)
  eq(h, 10)
  eq(m, 10)
  -- 0 → 5
  h, m = cal.step_time(10, 0, "min", 1)
  eq(h, 10)
  eq(m, 5)
  -- 3 → 5 / 3 → 0
  h, m = cal.step_time(10, 3, "min", 1)
  eq(h, 10)
  eq(m, 5)
  h, m = cal.step_time(10, 3, "min", -1)
  eq(h, 10)
  eq(m, 0)
end)

test("step_time: 分钟越界进位/借位到小时", function()
  -- 57 分 → 59:55? 不: 57 对齐到 60 → 下小时 0 分
  local h, m = cal.step_time(10, 57, "min", 1)
  eq(h, 11)
  eq(m, 0)
  -- 0 分向下 → 上小时 55 分
  h, m = cal.step_time(10, 0, "min", -1)
  eq(h, 9)
  eq(m, 55)
  -- 59 分 → 下小时 0 分
  h, m = cal.step_time(23, 59, "min", 1)
  eq(h, 0)
  eq(m, 0)
  -- 0:00 向下 → 23:55
  h, m = cal.step_time(0, 0, "min", -1)
  eq(h, 23)
  eq(m, 55)
end)

test("step_time: 自定义分钟步长", function()
  local h, m = cal.step_time(10, 0, "min", 1, 10)
  eq(h, 10)
  eq(m, 10)
  h, m = cal.step_time(10, 14, "min", 1, 10)
  eq(h, 10)
  eq(m, 20)
  h, m = cal.step_time(10, 50, "min", 1, 10)
  eq(h, 11)
  eq(m, 0)
end)

-- format_out
test("format_out: 仅日期", function()
  eq(cal.format_out(2026, 8, 1, 0, 0, false), "2026-08-01")
  eq(cal.format_out(2026, 12, 31, 0, 0, false), "2026-12-31")
end)

test("format_out: 带时间 (T 分隔)", function()
  eq(cal.format_out(2026, 8, 1, 10, 45, true), "2026-08-01T10:45:00")
  eq(cal.format_out(2026, 8, 1, 23, 5, true), "2026-08-01T23:05:00")
  eq(cal.format_out(2026, 8, 1, 0, 0, true), "2026-08-01T00:00:00")
end)
