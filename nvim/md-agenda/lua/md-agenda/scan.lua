-- 异步 rg 扫描 + readfile 切 block。
local M = {}

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

--- 给定文件与命中行号列表,readfile 后切 block
--- @param file string  绝对路径
--- @param lnums number[]  命中行号(1-based),已排序
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

  -- block 起始为命中行,结束为下一个命中行或空行
  local blocks = {}
  for i, start_lnum in ipairs(lnums) do
    local end_lnum
    -- 下一个命中行
    local next_start = lnums[i + 1]
    -- 逐行扫描直到空行或下一命中
    local l = start_lnum + 1
    while l <= #lines do
      if next_start and l == next_start then
        l = l - 1
        break
      end
      if lines[l] == "" then
        l = l - 1
        break
      end
      l = l + 1
    end
    end_lnum = l
    if end_lnum < start_lnum then end_lnum = start_lnum end

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
  return blocks
end

return M