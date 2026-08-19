-- 任务行编辑: 状态字符修改 + 完成时间戳([ts-end])读写。
-- 全插件对 [ts-end] 的唯一感知点;解析/agenda 数据层对其透明。
local M = {}
local date = require("md-agenda.date")

-- 前缀模式: #+ [c][ts] + tail
--   tail = 紧贴 ts 的可选 ts-end 方括号 + 空白 + 标题
--   lead = 捕获 #+ 用于回写
--   注意: 与 parse.lua 的 LINE_PAT 同源(仅多 lead 捕获组),修改时需同步
local LINE_PAT = "^(#+)%s%[(.)%]%[(.-)%](.*)$"

--- 解析任务行,切出 ts-end 与标题部分。
--- @param tail string  ts 括号之后的内容
--- @return string|nil ts_end  紧贴 ts 的方括号串(含 [])或 nil
--- @return string rest        空白 + 标题(或 nil = 不是合法任务行)
local function split_tail(tail)
  local ts_end, rest
  if tail:sub(1, 1) == "[" then
    local b = tail:match("^%[[^%]]*%]")
    if b then
      local after = tail:sub(#b + 1)
      if after:match("^%s") then
        ts_end, rest = b, after
      end
    end
  end
  if not rest then
    if tail:match("^%s") then
      rest = tail
    end
  end
  return ts_end, rest
end

--- 修改光标所在任务行的状态字符,并写入/删除 ts-end 完成时间戳。
--- @param char string  新的状态字符(单字符)
--- @param done boolean true=把 ts-end 刷新为当前时间(无则插入); false=删除 ts-end
function M.set_state(char, done)
  if type(char) ~= "string" or #char ~= 1 then
    vim.notify("md-agenda: 状态字符必须为单个字符", vim.log.levels.WARN)
    return
  end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local lead, _state, ts, tail = line:match(LINE_PAT)
  if not lead then
    vim.notify("md-agenda: 当前行不是任务行", vim.log.levels.WARN)
    return
  end

  local _ts_end, rest = split_tail(tail)
  if not rest then
    vim.notify("md-agenda: 当前行不是任务行", vim.log.levels.WARN)
    return
  end

  local new = lead .. " " .. "[" .. char .. "]" .. "[" .. ts .. "]"
  if done then
    new = new .. "[" .. date.now_ts() .. "]"
  end
  new = new .. rest

  vim.api.nvim_buf_set_text(0, lnum - 1, 0, lnum - 1, #line, { new })
end

return M
