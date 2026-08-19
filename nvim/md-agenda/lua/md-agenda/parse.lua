-- block 解析: 把 scan 切出的原始 block 转成 item 结构。
local M = {}
local date = require("md-agenda.date")

-- task 首行模式: ^#+ [c][ts] 标题
--   #+  = 任意标题级别(如 # / ## / ###)
--   c   = 单字符状态
--   ts  = 第一个方括号内容(可为空),由 date.parse_when 校验
--   标题 = 标记区后的内容,去前导空白
--   其余紧贴方括号(如 [ts-end] 完成时间戳)对解析透明,视为标题文本
-- 与 edit.lua 的 LINE_PAT 保持同步(后者多捕获一个 lead 用于回写)。
M.LINE_PAT = "^#+%s%[(.)%]%[(.-)%](.*)$"
local LINE_PAT = M.LINE_PAT

--- heading 级别(任何级别 heading,不必带 [c][ts] 标记)。
--- org 语义:heading 判定纯粹看 # 数量,与 TODO 关键字无关。
--- @param line string
--- @return number|nil  1=level-1 heading, 2=level-2, ...; 非 heading 返回 nil
function M.heading_level(line)
  local stars = line:match("^(#+)%s")
  return stars and #stars or nil
end

--- 判断一行是否为 task 首行(供 bulk_edit 检测 orphan 新 task 复用)。
--- @param line string
--- @return boolean
function M.is_task_line(line)
  return line:match(LINE_PAT) ~= nil
end

--- 解析单个 block
--- @param block table {file, start_lnum, end_lnum, lines={...}}
--- @return table|nil item  ts 非法时返回 nil
function M.parse_block(block)
  local first = block.lines[1]
  if not first then return nil end

  local state, ts, rest = first:match(LINE_PAT)
  if not state then return nil end

  local when = date.parse_when(ts)
  if when == nil then return nil end

  local title = rest:match("^%s*(.*)") or ""

  local body
  if #block.lines > 1 then
    body = table.concat(block.lines, "\n", 2)
  else
    body = ""
  end

  return {
    state = state,
    title = title,
    body = body,
    when = when,
    raw = block.lines[1],
    file = block.file,
    lnum = block.start_lnum,
    col = 1,
  }
end

--- 批量解析
--- @param blocks table[]
--- @return table[] items
function M.parse_blocks(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    local item = M.parse_block(b)
    if item then table.insert(out, item) end
  end
  return out
end

return M