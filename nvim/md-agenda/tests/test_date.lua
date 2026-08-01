-- date.lua 单元测试
local date = require("md-agenda.date")
test = test
eq = eq

-- parse_point
test("parse_point: 纯日期", function()
  eq(date.parse_point("2026-08-01"), "2026-08-01")
end)

test("parse_point: 日期+时间", function()
  eq(date.parse_point("2026-08-01T10:00:00"), "2026-08-01T10:00:00")
end)

test("parse_point: 非法格式", function()
  eq(date.parse_point("2026-8-1"), nil)
  eq(date.parse_point("2026-08-01T10:00"), nil)
  eq(date.parse_point("2026-08-01 10:00:00"), nil)
  eq(date.parse_point(nil), nil)
  eq(date.parse_point(""), nil)
end)

test("parse_point: 仅格式校验, 月/日范围不校验 (PLAN 设计)", function()
  -- 格式匹配即返回原串, 非法月/日由上层或日历 UI 校验
  eq(date.parse_point("2026-13-01"), "2026-13-01")
  eq(date.parse_point("2026-08-32"), "2026-08-32")
end)

-- parse_when
test("parse_when: always", function()
  eq(date.parse_when(""), { kind = "always" })
end)

test("parse_when: from", function()
  eq(date.parse_when("2026-08-01"), { kind = "from", date = "2026-08-01" })
  eq(date.parse_when("2026-08-01T10:00:00"), { kind = "from", date = "2026-08-01T10:00:00" })
end)

test("parse_when: until", function()
  eq(date.parse_when("/2026-08-31"), { kind = "until", date = "2026-08-31" })
  eq(date.parse_when("/2026-08-31T10:00:00"), { kind = "until", date = "2026-08-31T10:00:00" })
end)

test("parse_when: range", function()
  eq(date.parse_when("2026-08-01/2026-08-31"), { kind = "range", start = "2026-08-01", stop = "2026-08-31" })
  eq(date.parse_when("2026-08-01T10:00:00/2026-08-31"), { kind = "range", start = "2026-08-01T10:00:00", stop = "2026-08-31" })
end)

test("parse_when: 非法", function()
  eq(date.parse_when("/bad"), nil)
  eq(date.parse_when("bad/bad"), nil)
  eq(date.parse_when("2026-08-01/bad"), nil)
  eq(date.parse_when(nil), nil)
end)

-- to_date_key
test("to_date_key: 剥到天", function()
  eq(date.to_date_key("2026-08-01"), "2026-08-01")
  eq(date.to_date_key("2026-08-01T10:00:00"), "2026-08-01")
  eq(date.to_date_key(nil), nil)
end)

-- 日历纯函数
test("is_leap_year", function()
  eq(date.is_leap_year(2000), true)
  eq(date.is_leap_year(2024), true)
  eq(date.is_leap_year(1900), false)
  eq(date.is_leap_year(2026), false)
end)

test("days_in_month", function()
  eq(date.days_in_month(2024, 2), 29)
  eq(date.days_in_month(2026, 2), 28)
  eq(date.days_in_month(2026, 4), 30)
  eq(date.days_in_month(2026, 6), 30)
  eq(date.days_in_month(2026, 9), 30)
  eq(date.days_in_month(2026, 11), 30)
  eq(date.days_in_month(2026, 1), 31)
  eq(date.days_in_month(2026, 12), 31)
end)

test("iso_weekday", function()
  eq(date.iso_weekday(2024, 1, 1), 1) -- 周一
  eq(date.iso_weekday(2026, 8, 1), 6) -- 周六
  eq(date.iso_weekday(2026, 8, 2), 7) -- 周日
  eq(date.iso_weekday(2026, 8, 3), 1) -- 周一
  eq(date.iso_weekday(2026, 2, 1), 7) -- 周日
end)

test("strftime: 与 os.date 等价(回退路径)", function()
  eq(date.strftime("%Y-%m-%d"), os.date("%Y-%m-%d"))
end)
