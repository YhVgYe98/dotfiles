# md-agenda 实现规划

本文档自包含，不依赖任何前置对话上下文，可直接据此实现 7 个 Lua 文件。

## 目标

一个极简的 Neovim markdown task 管理插件，提供 org 风格的 capture + agenda。依赖 snacks.nvim 与 ripgrep，零自研 UI。

## Task 语法（严格）

行首匹配：

```
#+ [c][ts] 标题
```

Lua 模式：`^#+%s%[(.)%]%[(.-)%](.*)$`（rg 预过滤：`^#+\s\[.\](\[.*\])+\s`）

- 行首 `#+`（任意标题级别，markdown 可渲染），`#` 后须空白
- `[c]`：`c` 为任意单字符状态（` `、`x`、`-`、自定义均可），紧贴其后
- `[c]` 后可跟**一个或多个紧贴的方括号**（内容可为空），仅第一个用作 ts，其余（如 ts-end）对解析透明、视为标题文本
- 标记区后须空白，再接标题
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

- 起始：行首匹配 `^#+%s%[(.)%]%[(.-)%] `（任何 state、任何 ts，含空 `[]`）
- 结束：下一个此类匹配行，或空行
- 缩进子 checkbox（`^  - [x]...`）不匹配 `#+ [c][ts]`，归入父块 body，不作为独立 task
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
│       ├── edit.lua    任务行编辑: set_state 改状态字符 + 读写 ts-end（对 ts-end 的唯一感知点）
│       ├── ui.lua      snacks 适配层（唯一接触 snacks 的模块）
│       ├── calendar.lua 浮窗月历（移植 orgmode，纯逻辑可单测）
│       └── date.lua    ISO 8601 解析/格式化/校验 + 日历纯函数
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
    default = { desc = "Task", template = "# [ ][%^{from}] %?" },
  },
  default_states = { " ", "x" },
  keymaps = {
    capture = "<leader>mc",
    agenda = "<leader>ma",
    agenda_done = "<leader>md",
    set_state = "<leader>mx", -- set_state("x", true)
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

-- 异步 rg 扫 scan_dirs 下所有 .md，找出所有匹配 ^#+ \[.\]\[.*\] 的行
-- 回调 cb(file_lnums)，file_lnums = { [file] = {lnum1, lnum2, ...}, ... }
-- rg 参数：-n --with-filename --color=never -t markdown -e <pattern> <dirs>
-- pattern 转义为 rg regex: ^#+\s\[.\](\[.*\])+\s
--   #+ = 任意标题级别; [c] 单字符状态; 一个或多个紧贴方括号(内容可空); 标题前须空白
function M.scan(dirs, cb)

-- 给定 file 和命中的起始 lnum 列表，readfile 后切 block
-- 返回 { {file, start_lnum, end_lnum, lines}, ... }
-- block 起始为命中行，结束为下一命中行或空行（含空行则 block 不含空行）
function M.split_blocks(file, lnums)

return M
```

**scan**：用 `vim.system({"rg", ...}, {stdout=...})` 异步；收集输出行解析为 `file:lnum:line`。pattern 用 `^#+\s\[.\](\[.*\])+\s`（`.*` 贪心可吞多个括号，仅作匹配预过滤）。`-t markdown` 限定文件类型。

**split_blocks**：对每个文件 `vim.fn.readfile(file)` 一次，按命中 lnum 切块：从命中行起逐行累积，遇下一命中 lnum 或空行停止。返回 blocks。

### parse.lua

```lua
local M = {}
local date = require("md-agenda.date")

-- 解析单个 block → item 结构
-- block = {file, start_lnum, end_lnum, lines}
-- 返回 item 或 nil（ts 非法）
function M.parse_block(block)
  -- 1. 第一行匹配 ^#+%s%[(.)%]%[(.-)%](.*)$
  --    state = capture 1, ts = capture 2, rest = capture 3
  -- 2. title = rest 去前导空白（其余方括号如 ts-end 视为标题文本）
  -- 3. body = lines[2..] join "\n"
  -- 4. when = date.parse_when(ts)
  -- 5. 若 when == nil → 返回 nil
  -- 6. 返回 {state=, title=, body=, when=, file=, lnum=start_lnum, col=1}

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

### edit.lua

```lua
local M = {}
local date = require("md-agenda.date")

-- 完整任务行模式（set_state 用）：
--   #+       = 标题级别（重建时保留）
--   [c]      = 单字符状态
--   [ts]     = 时间窗口（第一个方括号）
--   [ts-end] = 紧贴 ts 的第三个方括号（内容可空），本模块读写
--   标题     = 标记区后，以空白开头
local LINE_PAT = "^(#+)%s%[(.)%]%[(.-)%](%[[^%]]*%])?(%s+.*)$"

-- 修改光标所在任务行的状态字符，并写入/删除 ts-end
-- char: 新的状态字符（单字符）
-- done: true=ts-end 刷新为当前时间（无则插入）；false=删除 ts-end
function M.set_state(char, done)
  -- 1. 校验 char 为单字符
  -- 2. 取光标当前行，匹配 LINE_PAT；不匹配 → notify 返回
  -- 3. 重建：lead .. " " .. "["..char.."]" .. "["..ts.."]"
  --         .. (done and "["..date.now_ts().."]" or "") .. rest
  -- 4. nvim_buf_set_text 整行替换（光标由 nvim 自动调整）
end

return M
```

- 全插件对 ts-end 的唯一感知点：解析/agenda 数据层对 ts-end 完全透明
- 位置式第三括号，不做内容校验；紧贴标题的方括号会被视为 ts-end（文档注明，现实几乎不出现）
- 已在 ts-end 时 done=true → 刷新为当前时间（不保留原完成时间）；done=false → 删除

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
local edit = require("md-agenda.edit")
local ui = require("md-agenda.ui")

M.config = {}

function M.setup(opts)
  M.config = config.setup(opts)
  -- 注册命令
  vim.api.nvim_create_user_command("MdCapture", function() capture.capture() end, { desc = "Capture task" })
  vim.api.nvim_create_user_command("MdAgenda", function() M.show(M.filter_by_states(M.collect(), M.config.default_states[1])) end, { desc = "Agenda (todo)" })
  vim.api.nvim_create_user_command("MdAgendaDone", function() M.show(M.filter_by_states(M.collect(), M.config.default_states[2])) end, { desc = "Agenda (done)" })
  -- 绑定默认键位（含 set_state → "x", true）
  -- ... M.config.keymaps
end

-- 公共 API（导出）
M.collect = agenda.collect
M.filter_by_states = agenda.filter_by_states
M.exclude_by_states = agenda.exclude_by_states
M.filter_active = agenda.filter_active
M.show = ui.show
M.capture = capture.capture
M.set_state = edit.set_state

return M
```

**默认命令封装（方案 A，纯状态，不套时间过滤）**：
- `:MdCapture` → `capture.capture()`
- `:MdAgenda` → `show(filter_by_states(collect(), " "))`
- `:MdAgendaDone` → `show(filter_by_states(collect(), "x"))`

时间过滤 `filter_active` 完全交给用户在 Lua 中调用，不隐式套进默认命令。

## lazy 集成

spec 放在 `nvim/fnl/plugins/ft/markdown.fnl`（markdown 文件类型相关插件，由 `plugins/init.fnl` 动态加载）：

```fennel
;;;;;;;;;; md-agenda ;;;;;;;;;;;;;
;; markdown task 管理: capture + agenda (本地插件, dir 指向 config/md-agenda)
(table.insert PKG (mt
    ["md-agenda"]
    :dir (.. (vim.fn.stdpath :config) "/md-agenda")
    :lazy true
    :ft ["markdown"]
    :cmd ["MdCapture" "MdAgenda" "MdAgendaDone"]
    :opts {:scan_dirs ["~/notes"]
           :capture_file "~/notes/journal/%Y-%m-%d.md"}
    :keys [(mt ["<leader>mc" "<cmd>MdCapture<cr>"] :desc "Capture task")
           (mt ["<leader>ma" "<cmd>MdAgenda<cr>"] :desc "Agenda (todo)")
           (mt ["<leader>md" "<cmd>MdAgendaDone<cr>"] :desc "Agenda (done)")
           (mt ["<leader>mx" #((call-at :md-agenda :set_state) "x" true)] :desc "Mark done (md-agenda)")]))
```

注意：`dir` 用本地路径指向 `nvim/md-agenda`，插件代码在该目录下。`:opts` 直接传给 `setup`。

## 实现顺序

1. ✅ **date.lua** — 纯 Lua，无依赖，可独立单测
2. ✅ **parse.lua** — 依赖 date，单测 block 解析
3. ✅ **scan.lua** — 依赖 vim.system + rg（用 io.lines 规避 fast event 限制）
4. ✅ **agenda.lua** — 依赖 scan + parse
5. ✅ **ui.lua** — 依赖 snacks（format="text" + layout preset="select" 单框无预览）
6. ✅ **capture.lua** — 依赖 ui + date（行尾用 startinsert! 修复 cursor 定位）
7. ✅ **config.lua** — 纯配置
8. ✅ **init.lua** — 组装
9. ✅ **fnl/plugins/ft/markdown.fnl** — lazy 集成（ft 文件类型插件目录，markdown buffer 时加载）
10. ✅ 校验：6 个测试套件 107 个测试全部通过；端到端 collect/filter/show 验证
11. ✅ **calendar.lua** — 浮窗月历（移植 orgmode，capture 日期选择器从文本对话框升级为月历）
12. ✅ 校验：tests/ 23 个测试全部通过（luajit tests/run.lua）；headless 验证打开/导航/时间模式/取消/翻月/from/range 全流程（tests/ 为本地开发用，不入库）
13. ✅ **edit.lua** — set_state 改状态字符 + 读写 ts-end；语法切换为 `# [c][ts] 标题`（任意标题级别，标记区可扩展）

## 实现过程中的关键修复

- **date.lua**：Lua 模式 `?` 不能修饰捕获组 `(T...)`，改用双模式分别匹配
- **scan.lua**：`vim.fn.readfile` 不能在 `vim.system` 的 fast event 回调中调用，改用 `io.lines`
- **capture.lua**：Lua 模式无 alternation，`render` 改用手动扫描占位符；`%^{from}` 不再加方括号（模板的 `[]` 已提供）；行尾 cursor 用 `startinsert!` 而非 `startinsert`
- **config.lua**：默认模板 `# [ ][%^{from}] %?`（state 与 ts 间无空格，匹配 task 语法）
- **ui.lua**：item 用 `data` 字段存跳转信息（不用 `file`/`pos`，避免触发 snacks 文件格式器）；`format = "text"` + `layout = { preset = "select" }` 实现单框无预览
- **calendar.lua**（移植自 nvim-orgmode `objects/calendar.lua`，MIT）：
  - 浮窗 36x14 居中，scratch buffer + bufhidden=wipe；BufWipeout 统一兜底 dispose（取消 → cb(nil)）
  - 高亮用 `nvim_buf_add_highlight`（不移植 orgmode 的 Range/colors 工具），今日 reverse / 选中日 underline
  - 光标→日期用渲染时记录的 `day_at` 映射（orgmode 用正则 `<cword>` 解析，本实现更精确）
  - 时间模式按用户实际体验实现：左右切 小时/分钟，上下调值，分钟步长固定（`min_step` 可配），非 orgmode 源码的三态步长
  - 修复：j/k（含方向键）日期模式方向反转（j 应下移 +1、k 上移 -1）；时间模式取反作为步进方向（k=上=增加，与 org 一致）
  - 修复：`step_time` 分钟先对齐到步长网格再步进（11 分 +5 → 15 而非 16），越界进位/借位到小时（57 → 下小时 0、0 向下 → 上小时 55）
  - 模块加载不接触 vim（纯逻辑可单测）；`read_date` 延迟 require ui.lua 避免循环依赖
  - `parse_point` 仅校验格式（PLAN 设计），日历 `i` 手动输入时额外校验真实日期范围
- **tests/**：纯 Lua 测试（无 busted 依赖），`luajit tests/run.lua` 运行；run.lua 用 arg[0] 定位脚本目录而非 cwd（本地开发用，不入仓库）

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
| task 语法 | `# [c][ts] 标题`，任意标题级别，`[c]` 后多个紧贴方括号 | markdown 可渲染（标题），与 checkbox 任务列表语义分离；标记区可扩展 |
| ts-end | 位置式第三括号，仅 `edit.lua/set_state` 感知 | 数据层不感知，`set_state` 按位置读写，无内容校验 |
| 标题边界 | 标记区后须空白 | 标记区与标题解耦，标题可含任意方括号 |
| block 边界 | 任何顶级 task 行（不论 state/ts） | 避免同状态块无空行时误合并 |
| 默认命令 | 方案 A（纯状态，不套时间） | 保持四函数可组合哲学 |
| UI | 复用 snacks.picker，集中在 ui.lua | 零自研 UI，解耦 snacks |
| capture 文件创建 | capture 时按需创建，不在 init 预建 | 避免污染非笔记会话 |
| show 排序 | v1 不排序 | 用户输入顺序，简化实现 |
| 重复任务 | v1 不解析 duration | scope 收敛，v2 扩展 |
| 日期选择器 | 自研浮窗月历（移植 orgmode，MIT） | 用户明确要求 org 风格日历；调研确认 nvim-orgmode 日历本身即自研浮窗而非 snacks 组件；无成熟第三方日历插件可用（mini.calendar 不存在），外部候选 star 数过低。打破"零自研 UI"决策，UI 代码集中在 calendar.lua |