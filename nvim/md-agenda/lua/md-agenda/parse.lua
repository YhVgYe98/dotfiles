-- block 解析: 把 scan 切出的原始 block 转成 item 结构。
local M = {}
local date = require("md-agenda.date")

-- task 首行模式: ^- [c][ts] title
--   c   = 单字符状态
--   ts  = 任意字符(含空),由 date.parse_when 校验
--   标题 = 第一个空格后的内容
local LINE_PAT = "^%- %[(.)%]%[(.-)%] (.+)$"

--- 解析单个 block
--- @param block table {file, start_lnum, end_lnum, lines={...}}
--- @return table|nil item  ts 非法时返回 nil
function M.parse_block(block)
  local first = block.lines[1]
  if not first then return nil end

  local state, ts, title = first:match(LINE_PAT)
  if not state then return nil end

  local when = date.parse_when(ts)
  if when == nil then return nil end

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