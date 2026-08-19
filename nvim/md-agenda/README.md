# md-agenda

一个极简的 Neovim 插件，用 markdown 管理 task，提供 org 风格的 task 插入 + agenda。基于 snacks.picker 与 ripgrep，无其他依赖。

## 特性

- **Task 语法**：`# [c][ts] 标题`（markdown 标题渲染，任意级别），`[c]` 后可跟多个紧贴方括号标记
- **时间戳**：ISO 8601，支持三种活跃窗口 + 永久活跃
- **Task 插入**：`:MdTask` 在当前 buffer 光标行上方插入模板渲染结果；交互式模板，日期/时间通过浮窗月历选择（org 风格，hjkl 导航，`t` 输入时间），也可手动输入
- **Agenda**：pipeline 式 API（收集 → 过滤 → 展示），高度可组合
- **可编辑 buffer**：`:MdAgenda` / `:MdAgendaDone` 打开跨文件聚合的临时 buffer，编辑后 `:w` 自动写回各源文件
- **零自研 UI**：复用 snacks.picker 的 fuzzy 搜索 + 预览 + 跳转（日历为移植 orgmode 的自研浮窗，MIT）

## Task 语法

行首匹配 `#+ [c][ts] 标题`（任意标题级别，如 `#`/`##`/`###`；`#` 后须空白）：

```
# [ ][2026-08-01] 从这天开始一直活跃
# [ ][/2026-08-31] 到这天为止活跃
# [ ][2026-08-01/2026-08-31] 这段时间内活跃
# [ ][] 永久活跃（ts 为空）
# [x][2026-08-01] 已完成
# [x][2026-08-01][2026-08-01T10:00:00] 已完成（ts-end 完成时间戳）
```

- `[c]` 固定单字符状态（` `、`x`、`-`、自定义均可），其后可跟**一个或多个紧贴的方括号**（内容可为空），仅第一个用作时间窗口 ts，其余（如 ts-end）对解析透明、视为标题文本
- 标记区后须空白，再接标题
- `ts` 为空 `[]` 表示任意时间都活跃
- `ts` 格式校验与 task 格式校验正交：ts 非法 → 该 task 不进 agenda（静默跳过）
- 时间戳可省略时间部分：`[2026-08-01]` 等价于 `[2026-08-01T00:00:00]`
- 支持区间：`[start/stop]`，两端均 ISO 8601
- **不**支持 ISO 8601 duration（`P1W` 等），留待 v2

### ts-end 完成时间戳

`set_state` 是插件对 ts-end 的唯一感知点：`done=true` 时把第三个方括号写为当前时间戳（无则插入、有则刷新），`done=false` 时删除。agenda 解析/过滤完全忽略它，当作标题文本。

### Block 多行（org mode subtree 语义）

md-agenda 借鉴 org mode 的 heading 树语义处理父子嵌套：

- **heading 识别**：行首 `#+\s`（任意级别，**不必带 `[c][ts]` 标记**）。
- **top-level task**：marked heading（`#+ [c][ts]`）在祖先链上无更浅的 marked heading → 是 top-level task，进 agenda。
- **子 marked heading**：归父 task 的 body，对 agenda 完全透明（状态不进 agenda，不单独显示）。
- **subtree 边界**：从 heading 行到下一个 `heading_level ≤ 当前 level` 的 heading 的前一行（剥尾随空行），或 EOF。
- **空行不算边界**：中间空行作为 body 一部分。
- **未标记 heading 作 section divider**：切断父 block（即使没有 `[c][ts]` 标记，同级或更浅的 heading 仍结束当前 subtree）。

```
# 2026-08-19                    ← 未 marked section divider
## [ ][2026-08-19] Task A       ← top-level task
### [ ][2026-08-19] Sub A       ← body of A（对 agenda 透明）
## [x][2026-08-19] Task B       ← top-level task（已完成）

# [ ][2026-08-01] Project      ← top-level task
intro
## [ ][2026-08-01] Phase 1     ← body of Project
### [x][2026-08-01] T1.1       ← body of Project
## [ ][2026-08-02] Phase 2     ← body of Project
# [ ][2026-08-02] Another      ← 另一个 top-level task
```

缩进子 checkbox（`  - [x]...`）不匹配 `#+ [c][ts]`，自然归入父块 body。

**用户给的难点例子**——未标记 `#` 在 marked `##` 之前，两个 marked heading 都是 top-level：

```
# 普通标题                       ← 未 marked heading
## [ ][2026-08-01] task          ← top-level task（栈空，是 top）
# [ ][2026-08-02] task1          ← top-level task（level 1 <= 2 弹栈后栈空，是 top）
```

## 安装

本插件以本地目录形式通过 lazy.nvim 加载。在你的 lazy spec 中加入：

```lua
{
  dir = "~/.config/nvim/md-agenda",
  cmd = { "MdTask", "MdAgenda", "MdAgendaDone" },
  keys = {
    { "<leader>mt", "<cmd>MdTask<cr>", desc = "Insert task" },
    { "<leader>ma", "<cmd>MdAgenda<cr>", desc = "Agenda (todo)" },
    { "<leader>md", "<cmd>MdAgendaDone<cr>", desc = "Agenda (done)" },
    { "<leader>mx", function() require("md-agenda").set_state("x", true) end, desc = "Mark done" },
  },
  opts = {
    scan_dirs = { "~/notes" },
    capture_file = "~/notes/journal/%Y-%m-%d.md",
  },
}
```

## 配置

```lua
require("md-agenda").setup({
  -- agenda 扫描的目录列表（rg 递归扫 .md）
  scan_dirs = { "~/notes" },

  -- bulk buffer 的 orphan 新 task :w 时追加到此文件。支持 strftime 模板
  capture_file = "~/notes/journal/%Y-%m-%d.md",

  -- task 插入模板。键为快捷选择标识
  templates = {
    default = {
      desc = "Task",
      template = "# [ ][%^{from}] %?",
    },
  },

  -- 默认状态字符：[1]=todo 用于 :MdAgenda, [2]=done 用于 :MdAgendaDone
  default_states = { " ", "x" },

  -- 浮窗日历：week_start 为 ISO 周起始（1=周一..7=周日），min_step 为时间模式下分钟步长
  calendar = {
    week_start = 1,
    min_step = 5,
  },

  -- 默认键位（也可在 lazy spec keys 里绑）
  keymaps = {
    task = "<leader>mt",
    agenda = "<leader>ma",
    agenda_done = "<leader>md",
    set_state = "<leader>mx", -- set_state("x", true): 标记完成
  },
})
```

## 命令

| 命令 | 行为 |
|---|---|
| `:MdTask` | 弹模板选择,渲染后在当前 buffer 光标行上方插入。在 bulk buffer 的 orphan 区插入时,`:w` 路由到 capture_file;在块内插入则成为该块 body 一部分 |
| `:MdAgenda` | 打开可编辑 bulk buffer,展示所有未完成 task(`filter_by_states(collect(), " ")`) |
| `:MdAgendaDone` | 打开可编辑 bulk buffer,展示所有已完成 task(`filter_by_states(collect(), "x")`) |

## 可编辑 bulk buffer

`MdAgenda` / `MdAgendaDone` 打开一个跨文件聚合的临时 buffer,所有未完成(或已完成)的 task 按源文件分组排列。用户与 task 的全部交互都在此 buffer 里完成,源文件无需打开。

### Buffer 格式

每个 task 块用 HTML 注释包裹(元数据自包含,buffer 仍是合法 markdown):

```
<!-- md-agenda:begin id=1 src=~/notes/project-a.md -->
# [ ][2026-08-01] Task 1
body line
<!-- md-agenda:end -->

# [ ][2026-08-20] 自由打字的新 task      ← 注释对之外 = 新 task,:w 时追加到 capture_file
```

### 编辑操作

- **改状态/标题/body** — 直接编辑文本;`<leader>mx` 在 task 行上仍可用来切换状态 + 管理 ts-end(与源文件一致)
- **删除整块** — 删掉 begin 注释、内容、end 注释三行(连同尾空行);`:w` 时该块从源文件删除
- **新建 task** — 在注释对之外的空行直接打 `# [c][ts] 标题` + 可选 body,或调 `:MdTask` 在光标处插入模板,`:w` 时追加到 `capture_file`
- **新建 sub-task** — 在父块 body 内光标处调 `:MdTask`(模板用 `##`),文本成为父块 body 一部分,`:w` 时写回父源文件
- **移动 task 到其他文件** — 改 begin 注释里的 `src=路径` 为另一个已存在的 .md 文件,`:w` 时从原文件删除 + 追加到新文件

### 写回(`:w`)

`:w` 触发 `BufWriteCmd`:

1. 状态机 parse buffer,识别每个 begin/end 包裹的块和注释对之外的 orphan 文本
2. 与渲染时记录的元数据对账:`replace`(内容变化)、`delete`(块缺失或全空)、`move`(src 改变)、`append`(orphan 新 task)
3. 按源文件分组,每个文件:
   - mtime 检测:自渲染后变了 → 整文件跳过 + 警告
   - 该文件已在某个 nvim buffer 中打开且 modified → 整文件跳过 + 警告
   - 否则按 start_lnum 降序应用 replace/delete,append 在文件尾(空行分隔)
4. orphan 新 task 追加到 `capture_file`(不存在则自动创建)
5. 重新 collect + 重新渲染 buffer,反映最新状态
6. set nomodified

### 边界情况

- **幂等 :w** — 无修改 → 全 skip,无 IO
- **malformed 块**(缺 begin 或 end 注释)→ 该块跳过 + 警告,不写回也不删除
- **重复 id** → 取首块,其余跳过 + 警告
- **未知 id**(用户改了注释里的 id)→ 跳过 + 警告
- **重开 `:MdAgenda` 时 bulk buffer 已 modified** → 询问 保存/丢弃/取消
- **filtered-out 状态的 task**(如 todos view 里的 done task)不在 buffer 中,`:w` 时不会被误删——元数据只记录本次渲染进 buffer 的块

## API

```lua
local M = require("md-agenda")

local all    = M.collect()                       -- 扫所有顶级带 ts 的 task block
local todos  = M.filter_by_states(all, " ")      -- 仅保留 state ∈ " " 的
local active = M.filter_active(todos, "2026-08-01", "2026-08-07")  -- [begin,end] 内活跃
M.bulk_edit(" ")                                  -- 打开 todos bulk buffer(等价 :MdAgenda)
```

| 函数 | 说明 |
|---|---|
| `collect()` | 异步 rg 扫 `scan_dirs`，解析所有顶级 task block，返回 items |
| `filter_by_states(items, states)` | 仅保留 state ∈ `states`（字符串，每个字符一个状态） |
| `exclude_by_states(items, states)` | 排除 state ∈ `states` |
| `filter_active(items, begin, end)` | 保留活跃窗口 ∩ `[begin, end]` ≠ ∅ 的（闭-闭，天粒度，ISO `"YYYY-MM-DD"`） |
| `bulk_edit(state_filter)` | 打开可编辑 bulk buffer,展示 `filter_by_states(collect(), state_filter)` 的 task;`:w` 写回 |
| `task()` | 在当前 buffer 光标行上方插入模板渲染结果(等价 `:MdTask`);路由靠光标位置决定 |
| `set_state(char, done)` | 光标在任务标题行时：改状态为 `char`；`done=true` 把 ts-end 刷新为当前时间（无则插入），`done=false` 删除 ts-end |

### 活跃窗口规则

| when 形式 | 活跃窗口 | 在 `[begin, end]` 内活跃 |
|---|---|---|
| `[]` (always) | `(-∞, ∞)` | 恒为 true |
| `[t]` (from) | `[t, ∞)` | `t ≤ end` |
| `[/t]` (until) | `(-∞, t]` | `begin ≤ t` |
| `[s/e]` (range) | `[s, e]` | `s ≤ end ∧ begin ≤ e` |

## Task 模板占位符

| 占位符 | 行为 |
|---|---|
| `%?` | 渲染后光标停留位置 |
| `%t` | 当前日期 `YYYY-MM-DD` |
| `%T` | 当前时间戳 `YYYY-MM-DDThh:mm:ss` |
| `%^{name}` | 交互式文本输入 |
| `%^{from}` | 弹浮窗月历选日期 → 填入模板的 `[]` 内（如 `[%^{from}]` → `[2026-08-01]`；按 `t` 可带时间 `[2026-08-01T10:00:00]`） |
| `%^{until}` | 弹浮窗月历 → 填入 `[/date]`（如 `[%^{until}]` → `[/2026-08-01]`） |
| `%^{range}` | 连续两次弹浮窗月历 → 填入 `[start/stop]`（如 `[%^{range}]` → `[2026-08-01/2026-08-31]`） |

### 浮窗日历键位

```
           八月 2026
 Mon  Tue  Wed  Thu  Fri  Sat  Sun
                          01   02
 03   04   05   06   07   08   09
 ...
               11:45
 [<] - prev month  [>] - next month
 [.] - today   [Enter] - select day
 [i] - enter date
 [t] - enter time
```

| 键 | 行为 |
|---|---|
| `h`/`j`/`k`/`l`、方向键 | 在日期格间移动（跨行自动跳到相邻格） |
| `<` / `>` | 上一月 / 下一月（支持 count） |
| `.` | 回到今天 |
| `i` | 手动输入日期（`YYYY-MM-DD` 或 `YYYY-MM-DDThh:mm:ss`） |
| `t` | 进入时间模式：左右键切换 小时/分钟，上下键调值（分钟按 `min_step` 步进，默认 5） |
| `T` | 清除时间（回到纯日期） |
| `d` | 从时间模式回到日期选择 |
| `<CR>` | 确认选择 |
| `q` / `<Esc>` | 取消 |

只选日期则不带时间（与 orgmode 行为一致）。

### `:MdTask` 行为说明

- 在当前 buffer 光标行上方插入模板渲染结果,**不打开任何文件、不写盘**
- 路由靠光标位置决定:
  - bulk buffer 的 orphan 区(注释对之外)→ `:w` bulk 时由 bulk_edit 路由到 `capture_file`
  - bulk buffer 的块内(注释对之间)→ `:w` bulk 时文本成为该块 body 一部分,写回该块源文件(若模板用 `##` 即 sub-task)
  - 普通 .md 文件 → 直接修改该文件,用户 `:w` 保存
  - 代码/配置文件 → 直接修改该文件,md-agenda 不扫非 .md(rg `-t markdown`),task 不进 agenda
- 只读 buffer(如 help、fugitive blame)→ notify "当前 buffer 不可修改"
- `capture_file` 的 strftime 模板由 bulk_edit 在 `:w` 时现算(避免跨午夜失效),不存在则建父目录 + 文件,追加时保证与最后非空行间留一个空行,末尾保留一个空行

## 依赖

- Neovim 0.10+
- [snacks.nvim](https://github.com/folke/snacks.nvim)（picker / input）
- [ripgrep](https://github.com/BurntSushi/ripgrep)

## License

MIT