-- bulk_edit: 可编辑临时 buffer 聚合多文件 task; :w 写回各源文件。
-- 元数据用 HTML 注释包裹每块自包含,纯文本状态机 parse,无 extmark。
-- 复用 agenda.collect / parse.is_task_line / capture.resolve_target_file。
local M = {}

local agenda = require("md-agenda.agenda")
local parse = require("md-agenda.parse")
local capture = require("md-agenda.capture")

-- 注释格式: <!-- md-agenda:begin id=N src=PATH --> ... <!-- md-agenda:end -->
local BEGIN_FMT = "<!-- md-agenda:begin id=%d src=%s -->"
local END_FMT = "<!-- md-agenda:end -->"
local BEGIN_PAT = "^<!%-%- md%-agenda:begin id=(%d+) src=(.+) %-%->$"
local END_PAT = "^<!%-%- md%-agenda:end %-%->$"

-- 单 buffer 模型:同时只存在一个 bulk buffer
local state = {
  buf = nil,
  filter = " ",
  meta = {},    -- id -> {file, start_lnum, end_lnum, orig_lines}
  mtimes = {},  -- file -> mtime at collect
  next_id = 1,
}

-- ========== helpers ==========

-- 从 item 还原原始 block 行(raw + body 拆分)
local function item_orig_lines(item)
  local lines = { item.raw }
  if item.body and item.body ~= "" then
    local rest = vim.split(item.body, "\n", { plain = true })
    vim.list_extend(lines, rest)
  end
  return lines
end

local function lines_equal(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

-- 按文件分组 items,同文件内按 lnum 升序
local function group_by_file(items)
  local by_file = {}
  for _, it in ipairs(items) do
    if not by_file[it.file] then by_file[it.file] = {} end
    table.insert(by_file[it.file], it)
  end
  for _, arr in pairs(by_file) do
    table.sort(arr, function(a, b) return a.lnum < b.lnum end)
  end
  return by_file
end

-- 找已加载的 nvim buffer(按文件绝对路径)
local function find_loaded_buf(path)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      if vim.api.nvim_buf_get_name(b) == path then return b end
    end
  end
  return nil
end

-- 状态机 parse buffer
-- 返回 blocks = {{id, src, new_lines, malformed?}}, orphans = list of lines
local function parse_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local blocks = {}
  local orphans = {}
  local cur = nil
  for i = 1, #lines do
    local line = lines[i]
    local bid, bsrc = line:match(BEGIN_PAT)
    if bid then
      if cur then
        cur.malformed = true
        table.insert(blocks, cur)
      end
      cur = { id = tonumber(bid), src = bsrc, new_lines = {} }
    elseif line:match(END_PAT) then
      if cur then
        table.insert(blocks, cur)
        cur = nil
      end
    else
      if cur then
        table.insert(cur.new_lines, line)
      else
        table.insert(orphans, line)
      end
    end
  end
  if cur then
    cur.malformed = true
    table.insert(blocks, cur)
  end
  return blocks, orphans
end

-- 从 orphan 行流提取新 task 块
-- task 首行(parse.is_task_line)起块;空行或下一 task 首行止
local function extract_new_tasks(orphans)
  local tasks = {}
  local cur = nil
  for _, line in ipairs(orphans) do
    if parse.is_task_line(line) then
      if cur then table.insert(tasks, cur) end
      cur = { line }
    elseif line == "" then
      if cur then
        table.insert(tasks, cur)
        cur = nil
      end
    else
      if cur then vim.list_extend(cur, { line }) end
    end
  end
  if cur then table.insert(tasks, cur) end
  return tasks
end

-- ========== render ==========

local function render(buf, items)
  local lines = {}
  state.meta = {}
  state.mtimes = {}
  state.next_id = 1

  local by_file = group_by_file(items)
  local files = {}
  for f, _ in pairs(by_file) do table.insert(files, f) end
  table.sort(files)

  for _, file in ipairs(files) do
    state.mtimes[file] = vim.fn.getftime(file)
    for _, it in ipairs(by_file[file]) do
      local id = state.next_id
      state.next_id = state.next_id + 1
      local orig = item_orig_lines(it)
      state.meta[id] = {
        file = file,
        start_lnum = it.lnum,
        end_lnum = it.lnum + #orig - 1,
        orig_lines = orig,
      }
      table.insert(lines, BEGIN_FMT:format(id, file))
      vim.list_extend(lines, orig)
      table.insert(lines, END_FMT)
      table.insert(lines, "")
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

-- ========== writeback ==========

-- 对单个文件应用 ops,replaces/deletes 按 start_lnum 降序,appends 在文件尾
-- 返回 ok, err
local function apply_ops_to_file(file, file_ops)
  -- mtime check
  if state.mtimes[file] and vim.fn.getftime(file) ~= state.mtimes[file] then
    return false, "mtime changed"
  end

  local loaded_buf = find_loaded_buf(file)
  if loaded_buf and vim.bo[loaded_buf].modified then
    return false, "loaded and modified in nvim"
  end

  local cur_lines
  if loaded_buf then
    cur_lines = vim.api.nvim_buf_get_lines(loaded_buf, 0, -1, false)
  else
    local f = io.open(file, "r")
    if not f then
      -- 文件不存在:若有 replace/delete op 则失败,只有 append 则从空开始(创建)
      if #file_ops.replaces > 0 or #file_ops.deletes > 0 then
        return false, "file not found with replace/delete ops"
      end
      cur_lines = {}
      -- 确保父目录存在
      local dir = vim.fn.fnamemodify(file, ":h")
      if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
      end
    else
      cur_lines = {}
      for l in f:lines() do table.insert(cur_lines, l) end
      f:close()
    end
  end

  -- 合并 replace/delete,降序处理(后续块行号不受前面 op 影响)
  local all = {}
  for _, r in ipairs(file_ops.replaces) do
    table.insert(all, { type = "replace", start_lnum = r.start_lnum, end_lnum = r.end_lnum, new_lines = r.new_lines })
  end
  for _, d in ipairs(file_ops.deletes) do
    table.insert(all, { type = "delete", start_lnum = d.start_lnum, end_lnum = d.end_lnum })
  end
  table.sort(all, function(a, b) return a.start_lnum > b.start_lnum end)

  for _, op in ipairs(all) do
    local s, e = op.start_lnum, op.end_lnum
    local remove_count = e - s + 1
    if op.type == "delete" then
      -- 同时删尾随空行(块分隔)
      local extra = 0
      if cur_lines[e + 1] == "" then extra = 1 end
      for _ = 1, remove_count + extra do
        table.remove(cur_lines, s)
      end
    else
      for _ = 1, remove_count do
        table.remove(cur_lines, s)
      end
      for i, l in ipairs(op.new_lines) do
        table.insert(cur_lines, s + i - 1, l)
      end
    end
  end

  -- appends:文件尾,空行分隔(空文件首块不加分隔) + 尾空行
  if #file_ops.appends > 0 then
    while #cur_lines > 0 and cur_lines[#cur_lines] == "" do
      table.remove(cur_lines)
    end
    for _, app in ipairs(file_ops.appends) do
      if #cur_lines > 0 then
        table.insert(cur_lines, "")
      end
      for _, l in ipairs(app) do
        table.insert(cur_lines, l)
      end
    end
    table.insert(cur_lines, "")
  end

  if loaded_buf then
    vim.api.nvim_buf_set_lines(loaded_buf, 0, -1, false, cur_lines)
    local ok, err = pcall(vim.api.nvim_buf_call, loaded_buf, function()
      vim.cmd("noautocmd write")
    end)
    if not ok then return false, "write failed: " .. tostring(err) end
  else
    local ok, err = pcall(vim.fn.writefile, cur_lines, file)
    if not ok then return false, "write failed: " .. tostring(err) end
  end
  state.mtimes[file] = vim.fn.getftime(file)
  return true
end

--- 写回当前 bulk buffer:parse → diff → 逐文件 apply → 重新渲染。
function M.writeback(buf)
  if buf ~= state.buf then
    vim.notify("md-agenda: buffer 状态不一致", vim.log.levels.ERROR)
    return
  end

  local blocks, orphans = parse_buffer(buf)
  local ops = {}  -- file -> { replaces={}, deletes={}, appends={} }
  local seen = {}

  for _, blk in ipairs(blocks) do
    if seen[blk.id] then
      vim.notify(("md-agenda: 重复 id=%s,取首块"):format(blk.id), vim.log.levels.WARN)
      goto continue
    end
    seen[blk.id] = true

    if blk.malformed then
      vim.notify(("md-agenda: 块 id=%s 缺 end 注释,跳过"):format(blk.id), vim.log.levels.WARN)
      goto continue
    end
    local meta = state.meta[blk.id]
    if not meta then
      vim.notify(("md-agenda: 未知 id=%s,跳过"):format(blk.id), vim.log.levels.WARN)
      goto continue
    end

    local all_empty = true
    for _, l in ipairs(blk.new_lines) do
      if l ~= "" then all_empty = false; break end
    end

    if blk.src ~= meta.file then
      -- 移动语义:从原文件删 + 追加到新文件
      if vim.fn.filereadable(blk.src) ~= 1 then
        vim.notify(("md-agenda: 移动目标不存在 %s,跳过 id=%s"):format(blk.src, blk.id), vim.log.levels.WARN)
        goto continue
      end
      ops[meta.file] = ops[meta.file] or { replaces = {}, deletes = {}, appends = {} }
      table.insert(ops[meta.file].deletes, { start_lnum = meta.start_lnum, end_lnum = meta.end_lnum })
      if not all_empty then
        ops[blk.src] = ops[blk.src] or { replaces = {}, deletes = {}, appends = {} }
        table.insert(ops[blk.src].appends, vim.deepcopy(blk.new_lines))
      end
    elseif all_empty then
      ops[meta.file] = ops[meta.file] or { replaces = {}, deletes = {}, appends = {} }
      table.insert(ops[meta.file].deletes, { start_lnum = meta.start_lnum, end_lnum = meta.end_lnum })
    elseif not lines_equal(blk.new_lines, meta.orig_lines) then
      ops[meta.file] = ops[meta.file] or { replaces = {}, deletes = {}, appends = {} }
      table.insert(ops[meta.file].replaces,
        { start_lnum = meta.start_lnum, end_lnum = meta.end_lnum, new_lines = vim.deepcopy(blk.new_lines) })
    end
    ::continue::
  end

  -- 检测 meta 有、buffer 无的 id = 用户在 buffer 里删除了整块(含注释)
  -- (注:state.meta 只含本次渲染进 buffer 的块,所以 filtered-out 的 done task 不会误删)
  for id, meta in pairs(state.meta) do
    if not seen[id] then
      ops[meta.file] = ops[meta.file] or { replaces = {}, deletes = {}, appends = {} }
      table.insert(ops[meta.file].deletes, { start_lnum = meta.start_lnum, end_lnum = meta.end_lnum })
    end
  end

  -- orphan 新 task → capture_file
  local new_tasks = extract_new_tasks(orphans)
  local cap_path = capture.resolve_target_file()
  if #new_tasks > 0 then
    ops[cap_path] = ops[cap_path] or { replaces = {}, deletes = {}, appends = {} }
    for _, t in ipairs(new_tasks) do
      table.insert(ops[cap_path].appends, t)
    end
  end

  local failures = 0
  for file, file_ops in pairs(ops) do
    local ok, err = apply_ops_to_file(file, file_ops)
    if not ok then
      failures = failures + 1
      vim.notify(("md-agenda: %s 跳过 (%s)"):format(file, err), vim.log.levels.WARN)
    end
  end

  -- 重新 collect + render,反映最新状态
  local all = agenda.collect()
  local items = agenda.filter_by_states(all, state.filter)
  render(buf, items)

  vim.bo[buf].modified = false
  local msg = "md-agenda: 写回完成"
  if failures > 0 then
    msg = msg .. (", %d 文件跳过"):format(failures)
  end
  vim.notify(msg, vim.log.levels.INFO)
end

-- ========== open ==========

--- 打开可编辑 bulk buffer,展示按 state_filter 过滤的 task。
--- @param state_filter string  状态字符串,如 " " 或 "x"
function M.open(state_filter)
  state.filter = state_filter or " "

  -- 关闭已存在的 bulk buffer(modified 时询问)
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    if vim.bo[state.buf].modified then
      local choice = vim.fn.confirm("bulk buffer 已修改", "保存\n丢弃\n取消", 1)
      if choice == 1 then
        M.writeback(state.buf)
      elseif choice == 2 then
        vim.api.nvim_buf_delete(state.buf, { force = true })
      else
        vim.api.nvim_set_current_buf(state.buf)
        return
      end
    else
      vim.api.nvim_buf_delete(state.buf, { force = true })
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "md-agenda://bulk")
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  state.buf = buf

  local group = vim.api.nvim_create_augroup("md_agenda_bulk", { clear = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    group = group,
    callback = function() M.writeback(buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    group = group,
    callback = function()
      if state.buf == buf then state.buf = nil end
    end,
    once = true,
  })

  local all = agenda.collect()
  local items = agenda.filter_by_states(all, state.filter)
  render(buf, items)
end

return M
