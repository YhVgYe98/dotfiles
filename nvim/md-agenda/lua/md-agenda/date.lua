-- ISO 8601 解析/格式化/校验。纯 Lua,无 nvim 依赖。
local M = {}

-- 单点 ISO 8601: "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
-- 成功返回原串,失败返回 nil
local DATE_PAT = "^%d%d%d%d%-%d%d%-%d%d$"
local DATETIME_PAT = "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d$"

--- 校验单点时间戳字符串。
--- @param s string
--- @return string|nil  合法则返回原串,非法返回 nil
function M.parse_point(s)
  if type(s) ~= "string" then return nil end
  if s:match(DATE_PAT) or s:match(DATETIME_PAT) then return s end
  return nil
end

--- 解析 ts 内容(不含外层 []),返回 when 结构或 nil。
---   ""          -> {kind="always"}
---   "t"         -> {kind="from",   date=t}
---   "/t"        -> {kind="until",  date=t}
---   "s/e"       -> {kind="range",  start=s, stop=e}
---   非法        -> nil
--- @param s string|nil
--- @return table|nil
function M.parse_when(s)
  if s == nil then return nil end
  if s == "" then return { kind = "always" } end

  -- until: /t
  if s:sub(1, 1) == "/" then
    local t = M.parse_point(s:sub(2))
    if t then return { kind = "until", date = t } end
    return nil
  end

  -- range: s/e
  local sep = s:find("/")
  if sep then
    local l = M.parse_point(s:sub(1, sep - 1))
    local r = M.parse_point(s:sub(sep + 1))
    if l and r then return { kind = "range", start = l, stop = r } end
    return nil
  end

  -- from: t
  local t = M.parse_point(s)
  if t then return { kind = "from", date = t } end
  return nil
end

--- 剥到天粒度 key "YYYY-MM-DD",用于 filter_active 比较。
--- @param s string
--- @return string|nil
function M.to_date_key(s)
  if type(s) ~= "string" then return nil end
  return s:sub(1, 10)
end

--- 生成 when 的人类可读描述,用于 picker 文本。
--- @param when table|nil
--- @return string
function M.describe_when(when)
  if not when then return "?" end
  local k = when.kind
  if k == "always" then return "always" end
  if k == "from" then return "from " .. M.to_date_key(when.date) end
  if k == "until" then return "until " .. M.to_date_key(when.date) end
  if k == "range" then
    return M.to_date_key(when.start) .. " -> " .. M.to_date_key(when.stop)
  end
  return "?"
end

--- 格式化当前时间为 ISO 日期 "YYYY-MM-DD"。
--- @return string
function M.now_date()
  return os.date("%Y-%m-%d")
end

--- 格式化当前时间为 ISO 时间戳 "YYYY-MM-DDThh:mm:ss"。
--- @return string
function M.now_ts()
  return os.date("%Y-%m-%dT%H:%M:%S")
end

--- v2 占位:展开重复任务(duration 如 P1W)。v1 始终返回 nil。
--- @param _when table
--- @param _today string
--- @return table|nil  v2: 返回展开后的 when 列表;v1 始终 nil
function M.expand_repeat(_when, _today)
  return nil
end

-- ========== 日历纯函数(浮窗月历用) ==========

--- 判断闰年(公历)。
--- @param y number
--- @return boolean
function M.is_leap_year(y)
  return y % 400 == 0 or (y % 100 ~= 0 and y % 4 == 0)
end

--- 某月天数。
--- @param y number
--- @param m number  1-12
--- @return number
function M.days_in_month(y, m)
  if m == 2 then return M.is_leap_year(y) and 29 or 28 end
  if m == 4 or m == 6 or m == 9 or m == 11 then return 30 end
  return 31
end

--- ISO 星期几:周一=1 .. 周日=7。
--- @param y number
--- @param m number
--- @param d number
--- @return number
function M.iso_weekday(y, m, d)
  local ts = os.time({ year = y, month = m, day = d })
  local wday = tonumber(os.date("%w", ts)) -- 0=周日..6=周六
  return (wday + 6) % 7 + 1
end

local function ends_with(s, suffix)
  return #s >= #suffix and s:sub(-#suffix) == suffix
end

-- 本地化日期格式化: 临时切到 UTF-8 locale(如 zh_CN.UTF-8 → 中文月份名),
-- 切换失败则回退 os.date。纯 Lua, 无 nvim 依赖。
--- @param fmt string
--- @param ts number|nil
--- @return string
function M.strftime(fmt, ts)
  ts = ts or os.time()
  local orig = os.setlocale(nil, "time")
  if orig then
    local utf8_locale
    if ends_with(orig, ".UTF-8") or ends_with(orig, ".utf8") then
      utf8_locale = orig
    else
      utf8_locale = orig:gsub("%.[^.]+$", "") .. ".UTF-8"
    end
    local changed = os.setlocale(utf8_locale, "time")
    if changed then
      local out = os.date(fmt, ts)
      os.setlocale(orig, "time")
      return out
    end
  end
  return os.date(fmt, ts)
end

return M