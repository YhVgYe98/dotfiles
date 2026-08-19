-- 异步 rg 扫描 + readfile 切 block。
-- block 边界采用 org mode subtree 语义:
--   - heading 判定:^#+\s (任何级别,不必带 [c][ts] 标记)
--   - top-level task:marked heading 在祖先链上无更浅 marked heading
--   - subtree 边界:从 heading 行到下一 heading_level ≤ 当前 level 的前一行(剥尾随空行),或 EOF
--   - 空行不算边界,作为 body 内容
--   - markdown fenced code block (``` 或 ~~~) 内的行不视为 heading,
--     即使以 # 开头也不切断父块(避免代码内 # comment 被误判)
local M = {}
local parse = require("md-agenda.parse")

-- task 首行 rg 正则 (rg 用 BRE/ERE 风格, 这里用 -e 传 PCRE-like)
-- ^#+\s\[.\](\[.*\])+\s
--   #+  = 任意标题级别; [c] 单字符状态; 其后一个或多个紧贴方括号(内容可空); 标题前须空白
local RG_PATTERN = "^#+\\s\\[.\\](\\[.*\\])+\\s"

--- 异步 rg 扫描目录下的 .md,收集所有 task 首行
--- @param dirs string[] 目录列表(支持 ~)
--- @param cb fun(file_lnums: table)  file_lnums = { [abs_path] = {lnum1,...}, ... }
function M.scan(dirs, cb)
  local expanded = {}
  for _, d in ipairs(dirs) do
    table.insert(expanded, vim.fn.expand(d))
  end

  local args = { "rg", "-n", "--with-filename", "--color=never", "-t", "markdown", "-e", RG_PATTERN }
  for _, d in ipairs(expanded) do
    table.insert(args, d)
  end

  local stdout = {}
  local result = {}

  local function done()
    -- 解析 stdout 行: file:lnum:line
    -- 非贪心取第一个 :lnum: 三元组; 行内容若含 :数字: 也不会干扰
    -- (路径中含 : 时回溯仍可正确分界, 除非路径本身含 :数字:)
    for _, line in ipairs(stdout) do
      local head, lnum_str = line:match("^(.-):(%d+):")
      if head and lnum_str then
        local lnum = tonumber(lnum_str)
        if lnum then
          result[head] = result[head] or {}
          table.insert(result[head], lnum)
        end
      end
    end
    cb(result)
  end

  local j = vim.system(args, {
    stdout = function(err, data)
      if data then
        for line in data:gmatch("[^\n]+") do
          table.insert(stdout, line)
        end
      end
    end,
    stderr = function(_, _) end,
  }, function()
    done()
  end)

  -- 保存 job 句柄避免被 GC
  M._job = j
end

-- 给定文件所有行 + marked heading 行号列表(已排序),用栈算法算 top-level 集合。
-- 返回 is_top = { [lnum] = true/false },只对 marked lnums 设值。
-- 算法:扫 marked lnums,弹出栈顶所有 level >= 当前的(祖先级别更浅才保留);栈空 = top-level。
local function compute_top_level(lines, marked_lnums)
  local marked_level = {}
  for _, ln in ipairs(marked_lnums) do
    marked_level[ln] = parse.heading_level(lines[ln])
  end

  local is_top = {}
  local stack = {}
  for _, ln in ipairs(marked_lnums) do
    local lvl = marked_level[ln]
    while #stack > 0 and marked_level[stack[#stack]] >= lvl do
      table.remove(stack)
    end
    is_top[ln] = (#stack == 0)
    table.insert(stack, ln)
  end
  return is_top
end

-- 检测一行是否为 fenced code block 的围栏行(开/闭均返回 true)。
-- CommonMark 规则:行首 0-3 空格 + 3+ 个 ` 或 ~;开 fence 后可接 info string,闭 fence 后只能有空白。
-- 返回 fence 字符("`" 或 "~")或 nil。
local function fence_char(line)
  local stripped = line:match("^%s*(%S.*)")
  if not stripped then return nil end
  local c = stripped:sub(1, 1)
  if c ~= "`" and c ~= "~" then return nil end
  -- 整行前缀是否全是同一字符(3+ 个)
  local run = stripped:match("^[`~]+")
  if not run or #run < 3 then return nil end
  if run:sub(1, 1) ~= c then return nil end
  return c
end

-- 给定 top-level marked heading 行号 + 文件所有行,扫到下一 heading_level ≤ 它的前一行(剥尾随空行),或 EOF。
-- 维护 fenced code block 状态:fence 内的行不视为 heading,即使以 # 开头。
-- 返回 end_lnum(>= start_lnum,确保至少含 heading 本行)。
local function compute_subtree_end(lines, start_lnum, lvl)
  local end_lnum = #lines
  local in_fence = false
  local fence_c = nil
  for i = start_lnum + 1, #lines do
    local line = lines[i]
    local fc = fence_char(line)
    if in_fence then
      -- 在 fence 内:同字符的围栏行视为闭合 fence
      if fc and fc == fence_c then
        in_fence = false
        fence_c = nil
      end
      -- fence 内的行一律不视为 heading
    else
      if fc then
        -- 开 fence
        in_fence = true
        fence_c = fc
      else
        local l = parse.heading_level(line)
        if l and l <= lvl then
          end_lnum = i - 1
          break
        end
      end
    end
  end
  -- 剥尾随空行(org-end-of-subtree 默认语义)
  while end_lnum > start_lnum and lines[end_lnum] == "" do
    end_lnum = end_lnum - 1
  end
  return end_lnum
end

--- 给定文件与命中行号列表,readfile 后按 org subtree 语义切 block。
--- 接口签名未变:输入 marked heading lnums,输出只含 top-level 的 blocks。
--- 子 marked heading 自然归入父 block 的 lines 范围,不独立产 block。
--- @param file string  绝对路径
--- @param lnums number[]  命中行号(1-based,已排序)
--- @return table[]  blocks = { {file, start_lnum, end_lnum, lines}, ... }
function M.split_blocks(file, lnums)
  if not lnums or #lnums == 0 then return {} end

  -- 用 Lua io 读文件(避免 vim.fn.readfile 在 fast event 上下文受限)
  local f = io.open(file, "r")
  if not f then return {} end
  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  if #lines == 0 then return {} end

  -- rg 已保证 lnums 是 marked heading 行;排序防御
  table.sort(lnums)

  local is_top = compute_top_level(lines, lnums)

  local blocks = {}
  for _, start_lnum in ipairs(lnums) do
    if is_top[start_lnum] then
      local lvl = parse.heading_level(lines[start_lnum])
      local end_lnum = compute_subtree_end(lines, start_lnum, lvl)

      local block_lines = {}
      for k = start_lnum, end_lnum do
        table.insert(block_lines, lines[k])
      end
      table.insert(blocks, {
        file = file,
        start_lnum = start_lnum,
        end_lnum = end_lnum,
        lines = block_lines,
      })
    end
  end
  return blocks
end

return M