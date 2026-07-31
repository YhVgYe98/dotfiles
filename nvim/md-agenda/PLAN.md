# md-agenda 实现规划

本文档自包含，不依赖任何前置对话上下文，可直接据此实现 7 个 Lua 文件。

## 目标

一个极简的 Neovim markdown task 管理插件，提供 org 风格的 capture + agenda。依赖 snacks.nvim 与 ripgrep，零自研 UI。

## Task 语法（严格）

行首严格匹配：

```
- [c][ts] 标题
```

Lua 模式：`^- %[(.)%]%[(.-)%] `

- 行首 `- `（列 0，无缩进）
- `[c]`：`c` 为任意单字符状态（` `、`x`、`-`、自定义均可）
- `[ts]`：紧贴 `[c]`，中间无空格
- `]` 后必须一个空格，再接标题
- `ts` 可为空 `[]`（= 任意时间都活跃）

**ts 4 种合法形式**（由 `date.lua` 校验，与 task 格式正交）：

| 形式 | 语义 | when 结构 |
|---|---|---|
| `[]` | always 活跃 | `{kind="always"}` |
| `[t]` | 从 t 起一直活跃 | `{kind="from", date=t}` |
| `[/t]` | 到 t 为止活跃 | `{kind="until", date=t}` |
| `[s/e]` | [s, e] 区间活跃 | `{kind="range", start=s, stop=e}` |

`t`、`s`、`e` 均为 ISO 8601，时间部分可省略：
- `2026-08-01`（纯日期，等价 `2026-08-01T00:00:00`）
- `2026-08-01T10:00:00`（带时间）

ts 非法 → `when = nil` → 该 task 不进 agenda（静默跳过，不报错）。

**不**支持 ISO 8601 duration（`P1W` 等），留待 v2。

## Block 多行规则

从匹配行起，到下一个匹配行或空行止，整块作为一个 task。多行内容归入 task body。

- 起始：行首匹配 `^- %[(.)%]%[(.-)%] `（任何 state、任何 ts，含空 `[]`）
- 结束：下一个此类匹配行，或空行
- 缩进子 checkbox（`^  - [x]...`）不匹配 `^-`，归入父块 body，不作为独立 task
- `collect()` 只保留 ts 能被 date.lua 成功解析（含空 `[]`→always）的块；ts 非法 → when=nil → 不进 agenda

## 活跃窗口与 filter_active

按天粒度，闭-闭查询区间 `[begin, end]`，begin/end 为 ISO 日期串 `"YYYY-MM-DD"`。

"任务活跃窗口 ∩ 查询区间 ≠ ∅"则保留：

| when 形式 | 活跃窗口 | 在 [begin, end] 内活跃 |
|---|---|---|
| always | `(-∞, ∞)` | 恒 true |
| from(t) | `[t, ∞)` | `t ≤ end` |
| until(t) | `(-∞, t]` | `begin ≤ t` |
| range(s,e) | `[s, e]` | `s ≤ end ∧ begin ≤ e` |

when=nil（非法 ts）→ false（排除）。

比较时剥掉时间部分，只比日期串（ISO 日期串字典序即时间序）。

## 模块结构

```
nvim/md-agenda/                  插件根目录（lazy dir= 指向此处）
├── lua/
│   └── md-agenda/               require("md-agenda.*") 的查找根
│       ├── init.lua    setup(opts); 命令注册; 导出公共 API
│       ├── config.lua  默认配置 + deep-merge
│       ├── capture.lua 模板渲染; 目标文件解析+按需创建; 追加
│       ├── scan.lua    异步 rg + readfile 切 block
│       ├── parse.lua   block → item 结构
│       ├── agenda.lua  collect/filter_by_states/exclude_by_states/filter_active
│       ├── ui.lua      snacks 适配层（唯一接触 snacks 的模块）
│       └── date.lua    ISO 8601 解析/格式化/校验
├── README.md         用户文档
└── PLAN.md           本文件
```

## 各模块详细规格

### config.lua

```lua
local M = {}
M.defaults = {
  scan_dirs = { "~/notes" },
  capture_file = "~/notes/journal/%Y-%m-%d.md",
  templates = {
    default = { desc = "Task", template = "- [ ] [%^{from}] %?" },
  },
  default_states = { " ", "x" },
  keymaps = {
    capture = "<leader>mc",
    agenda = "<leader>ma",
    agenda_done = "<leader>md",
  },
}
function M.setup(opts) -- deep-merge 用户 opts 到 defaults，返回最终 config
return M
```

- `scan_dirs`：目录列表，rg 递归扫 `.md`
- `capture_file`：字符串支持 strftime 模板（`%Y-%m-%d` 等），capture 时现算
- `templates`：表，键为标识，值为 `{desc, template, target?}`
- `default_states`：`[1]` 用于 `:MdAgenda`，`[2]` 用于 `:MdAgendaDone`
- `keymaps`：默认键位

### date.lua

纯 Lua，无 nvim 依赖，可单测。

```lua
local M = {}

-- 解析 ts 内容（不含外层 []），返回 when 结构或 nil
-- s 为 "" → {kind="always"}
-- s 形如 "2026-08-01" 或 "2026-08-01T10:00:00" → {kind="from", date=...}
-- s 形如 "/2026-08-01" → {kind="until", date=...}
-- s 形如 "s/e" → {kind="range", start=..., stop=...}
-- 非法 → nil
function M.parse_when(s)

-- 校验单点 ISO 8601（日期或日期+时间），返回归一化字符串或 nil
function M.parse_point(s)
  -- 接受 "2026-08-01" 或 "2026-08-01T10:00:00"
  -- 归一化：纯日期补 T00:00:00？或保留原样只比较日期部分？
  -- 决策：保留原样字符串，比较时用 to_date_key() 剥到天

-- 将 ISO 串转为 "YYYY-MM-DD" 天粒度 key（用于 filter_active 比较）
function M.to_date_key(s)

-- 格式化当前时间为 ISO 日期 "YYYY-MM-DD"
function M.now_date()

-- 格式化当前时间为 ISO 时间戳 "YYYY-MM-DDThh:mm:ss"
function M.now_ts()

-- v2 占位：展开重复任务（duration 如 P1W），v1 始终返回 nil
function M.expand_repeat(when, today)

return M
```

**parse_when 算法**：
1. `s == ""` → `{kind="always"}`
2. `s` 以 `/` 开头 → `parse_point(s:sub(2))`，成功则 `{kind="until", date=point}`
3. `s` 含 `/`（非开头） → 用 `s:find("/")` 分割，左右各 `parse_point`，都成功则 `{kind="range", start=l, stop=r}`
4. 否则 → `parse_point(s)`，成功则 `{kind="from", date=point}`
5. 任何 parse_point 失败 → nil

**parse_point 正则**（Lua 模式）：
`^(%d%d%d%d%-%d%d%-%d%d)(T%d%d:%d%d:%d%d)?$`
匹配则返回原串（保留时间部分），不匹配返回 nil。

**to_date_key**：取前 10 字符 `s:sub(1, 10)`（即 `YYYY-MM-DD`）。

### scan.lua

```lua
local M = {}

-- 异步 rg 扫 scan_dirs 下所有 .md，找出所有匹配 ^- \[.\]\[.*\] 的行
-- 回调 cb(file_lnums)，file_lnums = { [file] = {lnum1, lnum2, ...}, ... }
-- rg 参数：-n --with-filename --color=never -t markdown -e <pattern> <dirs>
-- pattern 转义为 rg regex: ^- \[.\]\[.*\]   (注意 rg 中 \[ 需转义)
function M.scan(dirs, cb)

-- 给定 file 和命中的起始 lnum 列表，readfile 后切 block
-- 返回 { {file, start_lnum, end_lnum, lines}, ... }
-- block 起始为命中行，结束为下一命中行或空行（含空行则 block 不含空行）
function M.split_blocks(file, lnums)

return M
```

**scan**：用 `vim.system({"rg", ...}, {stdout=...})` 异步；收集输出行解析为 `file:lnum:line`。pattern 用 `^- \[.\]\[.*\] `（注意尾空格，确保是 task 而非普通 checkbox）。`-t markdown` 限定文件类型。

**split_blocks**：对每个文件 `vim.fn.readfile(file)` 一次，按命中 lnum 切块：从命中行起逐行累积，遇下一命中 lnum 或空行停止。返回 blocks。

### parse.lua

```lua
local M = {}
local date = require("md-agenda.date")

-- 解析单个 block → item 结构
-- block = {file, start_lnum, end_lnum, lines}
-- 返回 item 或 nil（ts 非法）
function M.parse_block(block)
  -- 1. 第一行匹配 ^- %[(.)%]%[(.-)%] (.+)
  --    state = capture 1, ts = capture 2, title = capture 3
  -- 2. body = lines[2..] join "\n"
  -- 3. when = date.parse_when(ts)
  -- 4. 若 when == nil → 返回 nil
  -- 5. 返回 {state=, title=, body=, when=, file=, lnum=start_lnum, col=1}

return M
```

**item 结构**：
```lua
{
  state = " ",           -- 单字符
  title = "...",         -- 首行标题（第一个空格后的内容）
  body = "...",           -- 多行正文，"\n" 连接
  when = {kind=...},     -- date.parse_when 结果
  file = "/abs/path.md",
  lnum = 10,             -- 块起始行号（1-based）
  col = 1,               -- 列（固定 1）
}
```

### agenda.lua

```lua
local M = {}
local scan = require("md-agenda.scan")
local parse = require("md-agenda.parse")

-- 收集所有顶级带 ts 的 task block
-- 扫 scan_dirs → 切 block → parse → 过滤掉 nil
-- 返回 items 列表
function M.collect()
  -- 同步包装异步：用 vim.wait 或回调式 API
  -- 决策：collect 内部同步等待 rg 完成（用 channel 或 vim.wait）
  -- 简单起见用 coroutine + vim.wait

-- 仅保留 state ∈ states（字符串，每个字符一个状态）
function M.filter_by_states(items, states)

-- 排除 state ∈ states
function M.exclude_by_states(items, states)

-- 保留活跃窗口 ∩ [begin, end] ≠ ∅ 的
-- begin, end: ISO "YYYY-MM-DD" 天粒度，闭-闭
function M.filter_active(items, begin, end)
  -- 对每个 item.when:
  --   always → true
  --   from(t) → date.to_date_key(t) <= end
  --   until(t) → begin <= date.to_date_key(t)
  --   range(s,e) → date.to_date_key(s) <= end and begin <= date.to_date_key(e)
  --   nil → false

return M
```

**collect 异步处理**：`scan.scan` 是异步的，`collect` 需要同步返回。用 `vim.uv.new_async` 或简单 channel：
```lua
function M.collect()
  local done = false
  local result = {}
  scan.scan(config.scan_dirs, function(file_lnums)
    -- 对每个 file 切 block + parse
    ...
    done = true
  end)
  -- 用 vim.wait 等待
  vim.wait(10000, function() return done end, 50)
  return result
end
```

### capture.lua

```lua
local M = {}
local date = require("md-agenda.date")
local ui = require("md-agenda.ui")

-- 渲染模板：展开占位符，交互式询问 %^{...}
-- template: 字符串
-- 返回渲染后的文本（多行）+ 光标偏移（%? 位置）
function M.render(template, cb)
  -- 扫描 template 找占位符：
  --   %? → 记录光标位置，移除
  --   %t → 替换为 date.now_date()
  --   %T → 替换为 date.now_ts()
  --   %^{name} → 交互：
  --     name=from → ui.input_date("From date", function(d) ... 替换为 [d])
  --     name=until → ui.input_date("Until date", function(d) ... 替换为 [/d])
  --     name=range → 两次 ui.input_date，替换为 [s/e]
  --     其他 → ui.input_text(name, function(t) ... 替换)
  -- 全部占位符处理完 → cb(rendered_text, cursor_offset)

-- 执行 capture：选模板 → 渲染 → 追加到目标文件
function M.capture()
  -- 1. 若只有一个模板直接用，否则 ui.pick 选
  -- 2. render(template, function(text, cursor)
  -- 3. resolve_target_file() → path（strftime 模板 + 建目录 + 建文件）
  -- 4. append_to_file(path, text)（前空行+尾空行规则）
  -- 5. vim.cmd.edit(path) 并定位光标到 cursor

-- 解析 capture_file（strftime 模板）→ 绝对路径
function M.resolve_target_file()

-- 追加到文件末尾，保证前空行 + 尾空行
function M.append_to_file(path, text)

return M
```

**append_to_file 算法**：
1. 若文件不存在 → 写 `text .. "\n"`，return
2. readfile → 去尾部空行 → 得 `lines`
3. 若 `lines` 为空（原文件全空白）→ 写 `text .. "\n"`
4. 否则 → 写 `table.concat(lines, "\n") .. "\n\n" .. text .. "\n"`

**render 异步**：因为 `%^{from}` 等需交互输入，render 是异步的（cb 形式）。占位符依次处理，前一个完成后处理后一个。

### ui.lua

唯一接触 snacks 的模块。接口通用，便于将来替换或回退。

```lua
local M = {}

-- 用 snacks.picker 渲染 items 列表
-- items: parse 返回的 item 列表
-- <CR> 跳转到 item.file:item.lnum:item.col
function M.show(items)
  -- 检测 snacks.picker 可用性
  -- 构建 snacks.picker.pick 的 items: {text=, file=, pos=, preview=}
  --   text: "[state] title  when  file:lnum"
  --   file: item.file
  --   pos: {item.lnum, item.col}
  -- format/preview 用 snacks 默认或简单自定义
  -- confirm 回调: vim.cmd.edit(file) + cursor 跳转

-- 交互式日期/时间输入
-- prompt: 提示文字
-- cb(date_str): 回调，date_str 为 "YYYY-MM-DD" 或 "YYYY-MM-DDThh:mm:ss"
-- 若只选日期则不带时间（与 orgmode 行为一致）
function M.input_date(prompt, cb)
  -- 优先用 snacks.input（若可用）
  -- 回退 vim.ui.select 预设快捷选项（今天/明天/手动输入）
  -- 校验输入合法性（调 date.parse_point）

-- 交互式文本输入
function M.input_text(prompt, cb)
  -- snacks.input 或 vim.ui.input

return M
```

**snacks 解耦**：所有 `require("snacks.picker")` / `require("snacks.input")` 调用只出现在 `ui.lua`。若 snacks 不可用，回退到 `vim.ui.select` / `vim.fn.input`。其他模块通过 `ui.show` / `ui.input_date` / `ui.input_text` 调用，不直接接触 snacks。

**show 的 picker item 文本格式**：
`[{state}] {title}  {when_desc}  {file_short}:{lnum}`
其中 `when_desc` 由 `date` 结构生成，如 `from 2026-08-01`、`until 2026-08-31`、`2026-08-01 → 2026-08-31`、`always`。

### init.lua

```lua
local M = {}
local config = require("md-agenda.config")
local agenda = require("md-agenda.agenda")
local capture = require("md-agenda.capture")
local ui = require("md-agenda.ui")

M.config = {}

function M.setup(opts)
  M.config = config.setup(opts)
  -- 注册命令
  vim.api.nvim_create_user_command("MdCapture", function() capture.capture() end, { desc = "Capture task" })
  vim.api.nvim_create_user_command("MdAgenda", function() M.show(M.filter_by_states(M.collect(), M.config.default_states[1])) end, { desc = "Agenda (todo)" })
  vim.api.nvim_create_user_command("MdAgendaDone", function() M.show(M.filter_by_states(M.collect(), M.config.default_states[2])) end, { desc = "Agenda (done)" })
  -- 绑定默认键位
  -- ... M.config.keymaps
end

-- 公共 API（导出）
M.collect = agenda.collect
M.filter_by_states = agenda.filter_by_states
M.exclude_by_states = agenda.exclude_by_states
M.filter_active = agenda.filter_active
M.show = ui.show
M.capture = capture.capture

return M
```

**默认命令封装（方案 A，纯状态，不套时间过滤）**：
- `:MdCapture` → `capture.capture()`
- `:MdAgenda` → `show(filter_by_states(collect(), " "))`
- `:MdAgendaDone` → `show(filter_by_states(collect(), "x"))`

时间过滤 `filter_active` 完全交给用户在 Lua 中调用，不隐式套进默认命令。

## lazy 集成

新建 `nvim/fnl/plugins/md-agenda.fnl`：

```fennel
(local {
    : set-opts
    : mt
    : req-at
    : call-at}
 (require :utils))

(local PKG {})

(table.insert PKG (mt
    ["md-agenda"]
    :dir (.. (vim.fn.stdpath :config) "/md-agenda")
    :cmd ["MdCapture" "MdAgenda" "MdAgendaDone"]
    :opts {:scan_dirs ["~/notes"]
           :capture_file "~/notes/journal/%Y-%m-%d.md"}
    :keys [(mt ["<leader>mc" "<cmd>MdCapture<cr>"] :desc "Capture task")
           (mt ["<leader>ma" "<cmd>MdAgenda<cr>"] :desc "Agenda (todo)")
           (mt ["<leader>md" "<cmd>MdAgendaDone<cr>"] :desc "Agenda (done)")]))

PKG
```

注意：`dir` 用本地路径指向 `nvim/md-agenda`，插件代码在该目录下。`:opts` 直接传给 `setup`。

同时需在 `nvim/fnl/plugins/init.fnl` 中加载该 spec（参照现有 `extras.fnl` 等 `table.insert PKG (require :plugins.xxx)` 模式，但 md-agenda 是独立功能模块，建议在 `init.fnl` 中显式加入或新建独立 require 入口）。

## 实现顺序

1. **date.lua** — 纯 Lua，无依赖，可独立单测
2. **parse.lua** — 依赖 date，单测 block 解析
3. **scan.lua** — 依赖 vim.system + rg
4. **agenda.lua** — 依赖 scan + parse
5. **ui.lua** — 依赖 snacks
6. **capture.lua** — 依赖 ui + date
7. **config.lua** — 纯配置
8. **init.lua** — 组装
9. **fnl/plugins/md-agenda.fnl** — lazy 集成
10. 校验：`nvim --headless` 加载测试

## v1 不做（留 v2）

- ISO 8601 duration（`P1W` 等）解析与重复任务展开（`date.expand_repeat` 占位 nil）
- `show` 排序（按送入顺序显示）
- tag 语法
- 自定义浮窗 UI（复用 snacks.picker）
- 子 task 作为独立 task

## 关键设计决策汇总

| 决策点 | 选择 | 理由 |
|---|---|---|
| 时间戳分隔符 | 方括号 `[...]` | 渲染安全、grep 友好、与 org inactive 约定吻合 |
| 时间语义表示 | 单 `when` 字段 + 3 种形式 + always | 比 SCHEDULED/DEADLINE/START 三字段更简洁 |
| task 语法 | 严格 `- [c][ts] title`（双方括号） | 与普通 checkbox 明确区分 |
| block 边界 | 任何顶级 task 行（不论 state/ts） | 避免同状态块无空行时误合并 |
| 默认命令 | 方案 A（纯状态，不套时间） | 保持四函数可组合哲学 |
| UI | 复用 snacks.picker，集中在 ui.lua | 零自研 UI，解耦 snacks |
| capture 文件创建 | capture 时按需创建，不在 init 预建 | 避免污染非笔记会话 |
| show 排序 | v1 不排序 | 用户输入顺序，简化实现 |
| 重复任务 | v1 不解析 duration | scope 收敛，v2 扩展 |