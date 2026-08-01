-- snacks 适配层:所有 snacks 调用只在此模块。回退到 vim.ui/vim.fn。
local M = {}
local date = require("md-agenda.date")
local config = require("md-agenda.config")
local ok_calendar, calendar = pcall(require, "md-agenda.calendar")

--- snacks.picker 是否可用
local function has_picker()
  local ok = pcall(require, "snacks.picker")
  return ok
end

--- snacks.input 是否可用
local function has_input()
  local ok, snacks = pcall(require, "snacks")
  return ok and snacks.input ~= nil
end

--- 用 snacks.picker 渲染 items 列表,<CR> 跳转到 file:lnum:col。
--- 单框无预览,每项显示 task 首行原文。
--- @param items table[]  parse 返回的 item 列表
function M.show(items)
  if not has_picker() then
    vim.notify("md-agenda: snacks.picker 不可用,无法显示 agenda", vim.log.levels.ERROR)
    return
  end

  local picker = require("snacks.picker")
  picker.pick({
    items = vim.tbl_map(function(it)
      return {
        text = it.raw or ("- [" .. it.state .. "] " .. it.title),
        data = { file = it.file, lnum = it.lnum, col = it.col - 1 },
      }
    end, items),
    title = "md-agenda",
    format = "text",
    layout = { preset = "select" },
    confirm = function(pick, item)
      pick:close()
      if not item or not item.data then return end
      vim.cmd("edit " .. vim.fn.fnameescape(item.data.file))
      vim.api.nvim_win_set_cursor(0, { item.data.lnum, item.data.col })
      vim.cmd("normal! zv")
    end,
  })
end

--- 交互式日期/时间输入:优先浮窗月历,回退文本输入。
--- 只选日期则不带时间(与 orgmode 行为一致)。
--- @param prompt string
--- @param cb fun(date_str: string)  date_str 为 "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
function M.input_date(prompt, cb)
  if ok_calendar then
    local cal_cfg = config.get().calendar or {}
    local ok2, err = pcall(function()
      calendar.pick({
        title = prompt,
        week_start = cal_cfg.week_start,
        min_step = cal_cfg.min_step,
      }, function(d)
        if d then cb(d) end
      end)
    end)
    if ok2 then return end
    vim.notify("md-agenda: 日历打开失败,回退文本输入: " .. tostring(err), vim.log.levels.WARN)
  end

  local function validate(s)
    if s == nil or s == "" then return nil end
    -- 接受纯日期或带时间
    local d = s:match("^(%d%d%d%d%-%d%d%-%d%d)$")
    if d then return d end
    local dt = s:match("^(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d)$")
    if dt then return dt end
    return nil
  end

  if has_input() then
    local snacks = require("snacks")
    snacks.input({
      prompt = prompt .. " (YYYY-MM-DD 或 YYYY-MM-DDThh:mm:ss)",
      default = date.now_date(),
    }, function(value)
      local v = validate(value)
      if v then cb(v) end
    end)
  else
    vim.ui.input({
      prompt = prompt .. " (YYYY-MM-DD 或 YYYY-MM-DDThh:mm:ss): ",
      default = date.now_date(),
    }, function(value)
      local v = validate(value)
      if v then cb(v) end
    end)
  end
end

--- 交互式文本输入。
--- @param prompt string
--- @param cb fun(text: string)
function M.input_text(prompt, cb)
  if has_input() then
    local snacks = require("snacks")
    snacks.input({ prompt = prompt }, function(value)
      if value then cb(value) end
    end)
  else
    vim.ui.input({ prompt = prompt .. ": " }, function(value)
      if value then cb(value) end
    end)
  end
end

--- 选择模板(若多于一个)。
--- @param templates table  { key = {desc=, template=, ...}, ... }
--- @param cb fun(key: string, tpl: table)
function M.pick_template(templates, cb)
  local keys = {}
  for k, _ in pairs(templates) do
    table.insert(keys, k)
  end
  if #keys == 0 then return end
  if #keys == 1 then
    cb(keys[1], templates[keys[1]])
    return
  end

  local choices = vim.tbl_map(function(k)
    return { text = k .. " - " .. (templates[k].desc or ""), key = k, tpl = templates[k] }
  end, keys)

  if has_picker() then
    local picker = require("snacks.picker")
    picker.pick({
      items = choices,
      title = "Select template",
      format = "text",
      layout = { preset = "select" },
      confirm = function(pick, item)
        pick:close()
        if item then cb(item.key, item.tpl) end
      end,
    })
  else
    vim.ui.select(choices, {
      prompt = "Select template",
      format_item = function(c) return c.text end,
    }, function(c)
      if c then cb(c.key, c.tpl) end
    end)
  end
end

return M