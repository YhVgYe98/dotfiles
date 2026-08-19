-- agenda 数据层: collect / filter_by_states / exclude_by_states / filter_active。
local M = {}
local scan = require("md-agenda.scan")
local parse = require("md-agenda.parse")
local date = require("md-agenda.date")
local config = require("md-agenda.config")

--- 收集所有顶级带 ts 的 task block。
--- 扫 config.scan_dirs → 切 block → parse → 过滤 nil。
--- @return table[] items
function M.collect()
  local cfg = config.get()
  local dirs = cfg.scan_dirs or {}
  if #dirs == 0 then return {} end

  local items = {}
  local done = false

  scan.scan(dirs, function(file_lnums)
    for file, lnums in pairs(file_lnums) do
      table.sort(lnums)
      local blocks = scan.split_blocks(file, lnums)
      local parsed = parse.parse_blocks(blocks)
      for _, it in ipairs(parsed) do
        table.insert(items, it)
      end
    end
    done = true
  end)

  -- 等待异步 rg 完成(超时则提示)
  local ok = vim.wait(10000, function() return done end, 50)
  if not ok then
    vim.notify("md-agenda: scan 超时,结果可能不完整", vim.log.levels.WARN)
  end
  return items
end

--- 仅保留 state ∈ states (字符串,每个字符一个状态)。
--- @param items table[]
--- @param states string  如 " x-"
--- @return table[]
function M.filter_by_states(items, states)
  if not states then return items end
  local set = {}
  for c in states:gmatch(".") do set[c] = true end
  local out = {}
  for _, it in ipairs(items) do
    if set[it.state] then table.insert(out, it) end
  end
  return out
end

--- 排除 state ∈ states。
--- @param items table[]
--- @param states string
--- @return table[]
function M.exclude_by_states(items, states)
  if not states then return items end
  local set = {}
  for c in states:gmatch(".") do set[c] = true end
  local out = {}
  for _, it in ipairs(items) do
    if not set[it.state] then table.insert(out, it) end
  end
  return out
end

--- 保留活跃窗口 ∩ [begin, end] ≠ ∅ 的(闭-闭,天粒度,ISO "YYYY-MM-DD")。
--- @param items table[]
--- @param begin_date string  "YYYY-MM-DD"
--- @param end_date string    "YYYY-MM-DD"
--- @return table[]
function M.filter_active(items, begin_date, end_date)
  local out = {}
  for _, it in ipairs(items) do
    local w = it.when
    if w then
      local keep = false
      if w.kind == "always" then
        keep = true
      elseif w.kind == "from" then
        local d = date.to_date_key(w.date)
        if d and d <= end_date then keep = true end
      elseif w.kind == "until" then
        local d = date.to_date_key(w.date)
        if d and begin_date <= d then keep = true end
      elseif w.kind == "range" then
        local s = date.to_date_key(w.start)
        local e = date.to_date_key(w.stop)
        if s and e and s <= end_date and begin_date <= e then keep = true end
      end
      if keep then table.insert(out, it) end
    end
  end
  return out
end

return M