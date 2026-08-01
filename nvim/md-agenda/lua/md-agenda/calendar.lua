-- 浮窗月历:移植自 nvim-orgmode 的 orgmode.objects.calendar (MIT)。
-- 纯逻辑部分(build_grid/step_time/format_out)无 nvim 依赖,可单测;
-- 浮窗 UI 部分仅在 pick() 调用时接触 nvim。
local M = {}
local date = require("md-agenda.date")

-- 窗口尺寸/布局常量(与 orgmode 一致)
local WIDTH = 36
local HEIGHT = 14
local TIME_ROW = 9 -- 1-based 时间行行号
local TIME_ROW_HOUR_COL = 16 -- 1-based 小时首位
local TIME_ROW_MIN_COL = 19 -- 1-based 分钟首位

-- ========== 纯逻辑 (可单测) ==========

--- 生成某月日历网格(6 行 × 7 列)。
--- @param year number
--- @param month number  1-12
--- @param week_start number  ISO 周起始:1=周一 .. 7=周日,默认 1
--- @return table[]  grid[row][col] = {day=number} 或 nil
function M.build_grid(year, month, week_start)
  week_start = week_start or 1
  local grid = {}
  for i = 1, 6 do grid[i] = {} end
  local dim = date.days_in_month(year, month)
  local col0 = (date.iso_weekday(year, month, 1) - week_start + 7) % 7
  local row, col = 1, col0
  for d = 1, dim do
    grid[row][col + 1] = { day = d }
    col = col + 1
    if col == 7 then
      col = 0
      row = row + 1
    end
  end
  return grid
end

--- 时间步进:分钟先对齐到步长网格再步进(如 11 分 +5 → 15 分),越界进位/借位到小时。
--- @param hour number
--- @param min number
--- @param part string  "hour" | "min"
--- @param dir number  1 = 增加, -1 = 减少
--- @param min_step number  分钟步长,默认 5
--- @return number, number  新 hour, min
function M.step_time(hour, min, part, dir, min_step)
  min_step = min_step or 5
  if part == "hour" then
    return (hour + dir) % 24, min
  end
  if dir < 0 then
    local m = math.floor(min / min_step) * min_step
    if m == min then m = m - min_step end
    if m < 0 then return (hour - 1) % 24, m + 60 end
    return hour, m
  end
  local m = (math.floor(min / min_step) + 1) * min_step
  if m >= 60 then return (hour + 1) % 24, m - 60 end
  return hour, m
end

--- 输出为 md-agenda ts 字符串。
--- @param year number
--- @param month number
--- @param day number
--- @param hour number
--- @param min number
--- @param has_time boolean
--- @return string  "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
function M.format_out(year, month, day, hour, min, has_time)
  local base = string.format("%04d-%02d-%02d", year, month, day)
  if has_time then
    return base .. string.format("T%02d:%02d:00", hour, min)
  end
  return base
end

-- ========== 浮窗 UI (需 nvim) ==========

local ns = nil

local function apply_hl(buf, line0, col0, col1, group)
  vim.api.nvim_buf_add_highlight(buf, ns, group, line0, col0, col1)
end

-- 网格格子在屏幕上的列(1-based,该格第一个数字位)
local function cell_col(c)
  return 2 + 5 * (c - 1)
end

local function render_time_line(self)
  local l_pad, r_pad = "               ", "              "
  local hh = self.has_time and string.format("%02d", self.hour) or "--"
  local mm = self.has_time and string.format("%02d", self.min) or "--"
  return l_pad .. hh .. ":" .. mm .. r_pad
end

local function render(self)
  vim.api.nvim_set_option_value("modifiable", true, { buf = self.buf })

  local lines = {}

  -- 标题: 月 年 (本地化, 如 "八月 2026")
  local ts = os.time({ year = self.y, month = self.m, day = 1 })
  local title = date.strftime("%B %Y", ts)
  title = string.rep(" ", math.floor((WIDTH - #title) / 2)) .. title
  table.insert(lines, title)

  -- 星期行 (本地化; 2024-01-01 是周一, 作基准日取名)
  local names = {}
  for i = 0, 6 do
    names[i + 1] = date.strftime("%a", os.time({ year = 2024, month = 1, day = 1 + i }))
  end
  local header = {}
  for i = 0, 6 do
    header[i + 1] = names[((i + self.week_start - 1) % 7) + 1]
  end
  table.insert(lines, " " .. table.concat(header, "  ") .. " ")

  -- 日网格 (记录每个格子的屏幕列, 供光标→日期解析)
  self.day_at = {}
  for row = 1, 6 do
    local cells = {}
    local map = {}
    for c = 1, 7 do
      local cell = self.grid[row][c]
      if cell then
        cells[c] = string.format("%02d", cell.day)
        local col1 = cell_col(c)
        map[col1] = cell.day
        map[col1 + 1] = cell.day
      else
        cells[c] = "  "
      end
    end
    table.insert(lines, " " .. table.concat(cells, "   ") .. " ")
    self.day_at[row + 2] = map
  end

  -- 时间行
  table.insert(lines, render_time_line(self))
  table.insert(lines, "")

  -- 帮助行
  table.insert(lines, " [<] - prev month  [>] - next month")
  table.insert(lines, " [.] - today   [Enter] - select day")
  table.insert(lines, " [i] - enter date")
  if self.time_active then
    table.insert(lines, " [d] - select day  [T] - clear time")
  elseif self.has_time then
    table.insert(lines, " [t] - enter time  [T] - clear time")
  else
    table.insert(lines, " [t] - enter time")
  end

  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, lines)
  vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)

  -- 帮助行 + 无时间时的时间行 → Comment
  for i = 11, 14 do
    apply_hl(self.buf, i - 1, 0, -1, "Comment")
  end
  if not self.has_time and not self.time_active then
    apply_hl(self.buf, TIME_ROW - 1, 0, -1, "Comment")
  end

  -- 今日 (reverse) / 选中日 (underline)
  local today = os.date("*t")
  for row = 1, 6 do
    for c = 1, 7 do
      local cell = self.grid[row][c]
      if cell then
        local line0 = row + 1 -- 屏幕行 row+2 → 0-based row+1
        local col1 = cell_col(c)
        if cell.day == today.day and self.m == today.month and self.y == today.year then
          apply_hl(self.buf, line0, col1 - 1, col1 + 1, "MdAgendaToday")
        end
        if cell.day == self.d then
          apply_hl(self.buf, line0, col1 - 1, col1 + 1, "MdAgendaSelected")
        end
      end
    end
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = self.buf })
end

local function cursor_to(self, row, col)
  vim.api.nvim_win_set_cursor(self.win, { row + 2, cell_col(col) - 1 })
end

local function row_valid_cols(grid, row)
  local cols = {}
  for c = 1, 7 do
    if grid[row][c] then table.insert(cols, c) end
  end
  return cols
end

-- hjkl/方向键移动; 越行边界时夹到相邻行最近的日期格
local function move_cursor(self, dr, dc)
  local line, col = vim.fn.line("."), vim.fn.col(".")
  local row = math.min(math.max(line - 2, 1), 6)
  local c = math.min(math.max(math.floor((col - 2) / 5) + 1, 1), 7)
  local nr, nc = row + dr, c + dc
  if nc < 1 then
    nr, nc = nr - 1, 7
  elseif nc > 7 then
    nr, nc = nr + 1, 1
  end
  if nr < 1 or nr > 6 then return end
  local cols = row_valid_cols(self.grid, nr)
  if #cols == 0 then return end
  local target
  for _, v in ipairs(cols) do
    if v >= nc then
      target = v
      break
    end
  end
  cursor_to(self, nr, target or cols[#cols])
end

local function jump_day(self)
  for row = 1, 6 do
    for c = 1, 7 do
      local cell = self.grid[row][c]
      if cell and cell.day == self.d then
        cursor_to(self, row, c)
        return
      end
    end
  end
end

local function cursor_day(self)
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local map = self.day_at[line]
  if not map then return nil end
  return map[col] or map[col - 1]
end

local function shift_month(self, delta)
  self.m = self.m + delta
  if self.m > 12 then
    self.m, self.y = 1, self.y + 1
  elseif self.m < 1 then
    self.m, self.y = 12, self.y - 1
  end
  self.d = 1
  self.grid = M.build_grid(self.y, self.m, self.week_start)
  render(self)
  jump_day(self)
end

local function go_today(self)
  local t = os.date("*t")
  self.y, self.m, self.d = t.year, t.month, t.day
  self.grid = M.build_grid(self.y, self.m, self.week_start)
  render(self)
  jump_day(self)
end

-- 时间模式: t 进入(左右切 小时/分钟, 上下调值, 分钟步长固定)
local function set_time(self)
  if not self.has_time then
    local t = os.date("*t")
    self.hour, self.min = t.hour, t.min
    self.has_time = true
  end
  self.time_active = true
  self.time_part = "hour"
  render(self)
  vim.api.nvim_win_set_cursor(self.win, { TIME_ROW, TIME_ROW_HOUR_COL - 1 })
end

local function clear_time(self)
  if not self.has_time then return end
  self.has_time = false
  self.hour, self.min = 0, 0
  self.time_active = false
  self.time_part = "hour"
  render(self)
  jump_day(self)
end

local function step_time_ui(self, dir)
  local h, m = M.step_time(self.hour, self.min, self.time_part, dir, self.min_step)
  self.hour, self.min = h, m
  render(self)
  local part_col = self.time_part == "hour" and TIME_ROW_HOUR_COL or TIME_ROW_MIN_COL
  vim.api.nvim_win_set_cursor(self.win, { TIME_ROW, part_col - 1 })
end

local function set_time_part(self, part)
  self.time_part = part
  local part_col = part == "hour" and TIME_ROW_HOUR_COL or TIME_ROW_MIN_COL
  vim.api.nvim_win_set_cursor(self.win, { TIME_ROW, part_col - 1 })
end

-- 时间模式下导航; 日期模式下 hjkl 移动
-- dr 在日期模式 = 行偏移 (j/下 +1, k/上 -1);
-- 时间模式取反作为步进方向 (k/上 +1 增加, j/下 -1 减少, 与 org 一致)
local function nav(self, dr, dc)
  if self.time_active then
    if dr ~= 0 then
      step_time_ui(self, -dr)
    else
      set_time_part(self, self.time_part == "hour" and "min" or "hour")
    end
    return
  end
  move_cursor(self, dr, dc)
end

local function read_date(self)
  local ui = require("md-agenda.ui") -- 延迟 require, 避免与 ui.lua 循环依赖
  ui.input_text("Enter date (YYYY-MM-DD 或 YYYY-MM-DDThh:mm:ss)", function(s)
    if not s or s == "" then return end
    local p = date.parse_point(s)
    if not p then
      vim.notify("md-agenda: 无效日期: " .. s, vim.log.levels.WARN)
      return
    end
    local y, m, d = p:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    y, m, d = tonumber(y), tonumber(m), tonumber(d)
    -- parse_point 仅校验格式, 这里再校验真实日期范围
    if not (m and m >= 1 and m <= 12 and d and d >= 1 and d <= date.days_in_month(y, m)) then
      vim.notify("md-agenda: 无效日期: " .. s, vim.log.levels.WARN)
      return
    end
    self.y, self.m, self.d = y, m, d
    local hh, mm = p:match("T(%d%d):(%d%d)")
    if hh then
      self.hour, self.min = tonumber(hh), tonumber(mm)
      self.has_time = true
    else
      self.has_time = false
    end
    self.time_active = false
    self.time_part = "hour"
    self.grid = M.build_grid(self.y, self.m, self.week_start)
    render(self)
    jump_day(self)
  end)
end

local function close(self, result)
  if self.closed then return end
  self.closed = true
  local cb = self.cb
  self.cb = nil
  pcall(vim.api.nvim_win_close, self.win, true)
  if cb then cb(result) end
end

local function dispose(self)
  if self.closed then return end
  self.closed = true
  local cb = self.cb
  self.cb = nil
  if cb then cb(nil) end
end

local function confirm(self)
  if not self.time_active then
    local day = cursor_day(self)
    if day then self.d = day end
  end
  local out = M.format_out(self.y, self.m, self.d, self.hour, self.min, self.has_time)
  close(self, out)
end

local function open_win(self)
  local win_opts = {
    relative = "editor",
    width = WIDTH,
    height = HEIGHT,
    style = "minimal",
    border = "rounded",
    row = math.floor(vim.o.lines / 2 - (2 + HEIGHT) / 2),
    col = math.floor(vim.o.columns / 2 - (1 + WIDTH) / 2),
    title = self.title,
    title_pos = "center",
  }
  self.prev_win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(self.buf, "md-agenda-calendar")
  self.win = vim.api.nvim_open_win(self.buf, true, win_opts)

  local group = vim.api.nvim_create_augroup("md_agenda_calendar", { clear = true })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = self.buf,
    group = group,
    callback = function()
      dispose(self)
    end,
    once = true,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    buffer = self.buf,
    group = group,
    callback = function()
      if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_set_config(self.win, win_opts)
      end
    end,
  })

  vim.api.nvim_set_option_value("wrap", false, { win = self.win })
  vim.api.nvim_set_option_value("scrolloff", 0, { win = self.win })
  vim.api.nvim_set_option_value("sidescrolloff", 0, { win = self.win })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = self.buf })

  local map_opts = { buffer = self.buf, silent = true, nowait = true }
  vim.keymap.set("n", "j", function() nav(self, 1, 0) end, map_opts)
  vim.keymap.set("n", "k", function() nav(self, -1, 0) end, map_opts)
  vim.keymap.set("n", "h", function() nav(self, 0, -1) end, map_opts)
  vim.keymap.set("n", "l", function() nav(self, 0, 1) end, map_opts)
  vim.keymap.set("n", "<Down>", function() nav(self, 1, 0) end, map_opts)
  vim.keymap.set("n", "<Up>", function() nav(self, -1, 0) end, map_opts)
  vim.keymap.set("n", "<Left>", function() nav(self, 0, -1) end, map_opts)
  vim.keymap.set("n", "<Right>", function() nav(self, 0, 1) end, map_opts)
  vim.keymap.set("n", "<", function() shift_month(self, -vim.v.count1) end, map_opts)
  vim.keymap.set("n", ">", function() shift_month(self, vim.v.count1) end, map_opts)
  vim.keymap.set("n", ".", function() go_today(self) end, map_opts)
  vim.keymap.set("n", "t", function() set_time(self) end, map_opts)
  vim.keymap.set("n", "T", function() clear_time(self) end, map_opts)
  vim.keymap.set("n", "d", function()
    if self.time_active then
      self.time_active = false
      self.time_part = "hour"
      render(self)
      jump_day(self)
    end
  end, map_opts)
  vim.keymap.set("n", "i", function() read_date(self) end, map_opts)
  vim.keymap.set("n", "<CR>", function() confirm(self) end, map_opts)
  vim.keymap.set("n", "q", function() close(self, nil) end, map_opts)
  vim.keymap.set("n", "<Esc>", function() close(self, nil) end, map_opts)
end

--- 打开浮窗日历。
--- @param opts table  {title?: string, default?: string, week_start?: number, min_step?: number}
---   default: "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
--- @param cb fun(date_str: string|nil)  确认 → 日期串; 取消/关闭 → nil
function M.pick(opts, cb)
  opts = opts or {}
  if ns == nil then
    ns = vim.api.nvim_create_namespace("md-agenda-calendar")
    vim.cmd([[hi default MdAgendaToday gui=reverse cterm=reverse]])
    vim.cmd([[hi default MdAgendaSelected gui=underline cterm=underline]])
  end

  local self = {
    title = opts.title or "Calendar",
    cb = cb,
    week_start = opts.week_start or 1,
    min_step = opts.min_step or 5,
    has_time = false,
    time_active = false,
    time_part = "hour",
    hour = 0,
    min = 0,
    closed = false,
  }

  local default = opts.default
  if default and default ~= "" then
    local y, m, d = default:match("^(%d%d%d%d)-(%d%d)-(%d%d)")
    if y then
      self.y, self.m, self.d = tonumber(y), tonumber(m), tonumber(d)
      local hh, mm = default:match("T(%d%d):(%d%d)")
      if hh then
        self.hour, self.min = tonumber(hh), tonumber(mm)
        self.has_time = true
      end
    end
  end
  if not self.y then
    local t = os.date("*t")
    self.y, self.m, self.d = t.year, t.month, t.day
  end

  self.grid = M.build_grid(self.y, self.m, self.week_start)
  self.day_at = {}
  open_win(self)
  render(self)
  jump_day(self)
end

return M
