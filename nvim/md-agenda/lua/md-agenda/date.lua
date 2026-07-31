-- ISO 8601 解析/格式化/校验。纯 Lua,无 nvim 依赖。
local M = {}

-- 单点 ISO 8601: "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
-- 成功返回原串,失败返回 nil
local DATE_PAT = "^%d%d%d%d%-%d%d%-%d%d$"
local DATETIME_PAT = "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d$"

function M.parse_point(s)
  if type(s) ~= "string" then return nil end
  if s:match(DATE_PAT) or s:match(DATETIME_PAT) then return s end
  return nil
end

-- 解析 ts 内容(不含外层 []),返回 when 结构或 nil
--   ""          -> {kind="always"}
--   "t"         -> {kind="from",   date=t}
--   "/t"        -> {kind="until",  date=t}
--   "s/e"       -> {kind="range",  start=s, stop=e}
--   非法        -> nil
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

-- 剥到天粒度 key "YYYY-MM-DD",用于 filter_active 比较
function M.to_date_key(s)
  if type(s) ~= "string" then return nil end
  return s:sub(1, 10)
end

-- 生成 when 的人类可读描述,用于 picker 文本
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

-- 格式化当前时间为 ISO 日期 "YYYY-MM-DD"
function M.now_date()
  return os.date("%Y-%m-%d")
end

-- 格式化当前时间为 ISO 时间戳 "YYYY-MM-DDThh:mm:ss"
function M.now_ts()
  return os.date("%Y-%m-%dT%H:%M:%S")
end

-- v2 占位:展开重复任务(duration 如 P1W)。v1 始终返回 nil。
function M.expand_repeat(_when, _today)
  return nil
end

return M