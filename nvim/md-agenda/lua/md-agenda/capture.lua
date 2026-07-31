-- capture: 模板渲染 + 目标文件解析 + 追加。
local M = {}
local date = require("md-agenda.date")
local ui = require("md-agenda.ui")
local config = require("md-agenda.config")

-- 手动扫描下一个占位符(避免依赖 Lua 模式的 alternation)
-- 返回 {pos=start, len=, kind=, name=} 或 nil
local function find_next_ph(s, from)
  local p = s:find("%%", from)
  if not p then return nil end
  local rest = s:sub(p + 1)
  -- %^{name}: % 后跟 ^{name}
  if rest:match("^%^%b{}") then
    local name = rest:match("^%^%{(%a+)%}")
    if name then
      local matched = rest:match("^%^%b{}")
      return { pos = p, len = 1 + #matched, kind = "named", name = name }
    end
  end
  -- %? / %t / %T: % 后跟单字符
  local c = rest:sub(1, 1)
  if c == "?" then return { pos = p, len = 2, kind = "cursor" } end
  if c == "t" then return { pos = p, len = 2, kind = "date" } end
  if c == "T" then return { pos = p, len = 2, kind = "time" } end
  return find_next_ph(s, p + 1)
end

--- 渲染模板:依次处理占位符,完成后回调。
--- @param template string
--- @param cb fun(text: string, cursor: number|nil)  cursor 为 %? 在最终文本中的字节偏移(1-based)
function M.render(template, cb)
  -- 收集所有占位符
  local phs = {}
  local i = 1
  while i <= #template do
    local ph = find_next_ph(template, i)
    if not ph then break end
    table.insert(phs, ph)
    i = ph.pos + ph.len
  end

  -- 切成 segments: 文本段 + 占位符槽
  local segments = {}
  local last = 1
  for _, ph in ipairs(phs) do
    if ph.pos > last then
      table.insert(segments, { text = template:sub(last, ph.pos - 1), is_ph = false })
    end
    table.insert(segments, { is_ph = true, ph = ph })
    last = ph.pos + ph.len
  end
  if last <= #template then
    table.insert(segments, { text = template:sub(last), is_ph = false })
  end

  local cursor = nil
  local idx = 1

  local function finish()
    local out = {}
    for _, seg in ipairs(segments) do
      if seg.is_ph then
        if seg.ph.kind == "cursor" then
          local prefix = table.concat(out)
          cursor = #prefix + 1
        else
          table.insert(out, seg.value or "")
        end
      else
        table.insert(out, seg.text)
      end
    end
    cb(table.concat(out), cursor)
  end

  local function next_ph()
    if idx > #segments then finish(); return end
    local seg = segments[idx]
    if not seg.is_ph then
      idx = idx + 1
      next_ph()
      return
    end

    local ph = seg.ph
    local function fill(v)
      seg.value = v
      idx = idx + 1
      next_ph()
    end

    if ph.kind == "cursor" then
      fill("")
    elseif ph.kind == "date" then
      fill(date.now_date())
    elseif ph.kind == "time" then
      fill(date.now_ts())
    elseif ph.kind == "named" then
      if ph.name == "from" then
        ui.input_date("From date", function(d) fill(d) end)
      elseif ph.name == "until" then
        ui.input_date("Until date", function(d) fill("/" .. d) end)
      elseif ph.name == "range" then
        ui.input_date("Range start", function(s)
          ui.input_date("Range stop", function(e) fill(s .. "/" .. e) end)
        end)
      else
        ui.input_text(ph.name, function(t) fill(t or "") end)
      end
    end
  end

  if #segments == 0 then
    cb(template, nil)
  else
    next_ph()
  end
end

--- 解析 capture_file (strftime 模板) → 绝对路径。
--- @return string
function M.resolve_target_file()
  local cfg = config.get()
  local tmpl = cfg.capture_file or "~/notes/journal/%Y-%m-%d.md"
  local expanded = os.date(tmpl)
  return vim.fn.expand(expanded)
end

--- 追加到文件末尾,保证前空行 + 尾空行规则。
--- @param path string  绝对路径
--- @param text string  要追加的内容(不含尾换行)
--- @return number  追加内容首行在文件中的行号(1-based)
function M.append_to_file(path, text)
  local text_lines = vim.split(text, "\n")

  if vim.fn.filereadable(path) == 0 then
    local dir = vim.fn.fnamemodify(path, ":h")
    vim.fn.mkdir(dir, "p")
    local out = vim.list_extend({}, text_lines)
    table.insert(out, "")
    vim.fn.writefile(out, path)
    return 1
  end

  local lines = vim.fn.readfile(path) or {}
  -- 去尾部空行
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end

  if #lines == 0 then
    local out = vim.list_extend({}, text_lines)
    table.insert(out, "")
    vim.fn.writefile(out, path)
    return 1
  end

  -- 前空行 + content + 尾空行
  local start = #lines + 2  -- +1 跳过原末行, +1 空行
  local out = vim.list_extend({}, lines)
  table.insert(out, "")
  for _, l in ipairs(text_lines) do table.insert(out, l) end
  table.insert(out, "")
  vim.fn.writefile(out, path)
  return start
end

--- 执行 capture:选模板 → 渲染 → 追加 → 打开文件定位光标。
function M.capture()
  local cfg = config.get()
  local templates = cfg.templates or {}
  if not next(templates) then
    vim.notify("md-agenda: 未配置 templates", vim.log.levels.WARN)
    return
  end

  ui.pick_template(templates, function(_key, tpl)
    M.render(tpl.template, function(text, cursor)
      local path = M.resolve_target_file()
      local start_lnum = M.append_to_file(path, text)
      vim.cmd("edit " .. vim.fn.fnameescape(path))

      -- 计算 cursor 在 text 中的行/列偏移
      local row_off, col = 0, 0
      if cursor then
        local before = text:sub(1, cursor - 1)
        for _ in before:gmatch("\n") do row_off = row_off + 1 end
        col = #before:match("([^\n]*)$")
      end
      local lnum = start_lnum + row_off
      vim.api.nvim_win_set_cursor(0, { lnum, col })
      -- 行尾(col >= 行长)用 startinsert! (A 语义, 行尾 append);
      -- 否则 startinsert (i 语义, 字符前插入)。避免 nvim 把行尾 col clamp 到最后字符。
      local line_len = #vim.api.nvim_get_current_line()
      if col >= line_len then
        vim.cmd("startinsert!")
      else
        vim.cmd("startinsert")
      end
    end)
  end)
end

return M