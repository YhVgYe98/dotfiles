# md-agenda

一个极简的 Neovim 插件，用 markdown 管理 task，提供 org 风格的 capture + agenda。基于 snacks.picker 与 ripgrep，无其他依赖。

## 特性

- **Task 语法**：`- [c][ts] 标题`，双方括号区分于普通 checkbox
- **时间戳**：ISO 8601，支持三种活跃窗口 + 永久活跃
- **Capture**：交互式模板，支持日期/时间选择（只选日期则不带时间，与 orgmode 行为一致）
- **Agenda**：pipeline 式 API（收集 → 过滤 → 展示），高度可组合
- **零自研 UI**：复用 snacks.picker 的 fuzzy 搜索 + 预览 + 跳转

## Task 语法

行首严格匹配 `- [c][ts] 标题`（state 与 ts 间无空格，ts 与标题间一个空格）：

```
- [ ][2026-08-01] 从这天开始一直活跃
- [ ][/2026-08-31] 到这天为止活跃
- [ ][2026-08-01/2026-08-31] 这段时间内活跃
- [ ][] 永久活跃（ts 为空）
- [x][2026-08-01] 已完成
```

- `c` 是任意单字符状态（` `、`x`、`-`、自定义均可）
- `ts` 为空 `[]` 表示任意时间都活跃
- `ts` 格式校验与 task 格式校验正交：ts 非法 → 该 task 不进 agenda（静默跳过）
- 时间戳可省略时间部分：`[2026-08-01]` 等价于 `[2026-08-01T00:00:00]`
- 支持区间：`[start/stop]`，两端均 ISO 8601
- **不**支持 ISO 8601 duration（`P1W` 等），留待 v2

### Block 多行

从匹配行起，到下一个匹配行或空行止，整块作为一个 task。多行内容归入 task body：

```
- [ ][2026-08-01] 周报
  详细说明第一行
  详细说明第二行

- [x][2026-08-02] 另一个任务
```

缩进子 checkbox（`^  - [x]...`）不作为独立 task，归入父块 body。

## 安装

本插件以本地目录形式通过 lazy.nvim 加载。在你的 lazy spec 中加入：

```lua
{
  dir = "~/.config/nvim/md-agenda",
  cmd = { "MdCapture", "MdAgenda", "MdAgendaDone" },
  keys = {
    { "<leader>mc", "<cmd>MdCapture<cr>", desc = "Capture task" },
    { "<leader>ma", "<cmd>MdAgenda<cr>", desc = "Agenda (todo)" },
    { "<leader>md", "<cmd>MdAgendaDone<cr>", desc = "Agenda (done)" },
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

  -- capture 写入文件。支持 strftime 模板（如 %Y-%m-%d），capture 时现算
  capture_file = "~/notes/journal/%Y-%m-%d.md",

  -- capture 模板。键为快捷选择标识
  templates = {
    default = {
      desc = "Task",
      template = "- [ ] [%^{from}] %?",
    },
  },

  -- 默认状态字符：[0]=todo 用于 :MdAgenda, [1]=done 用于 :MdAgendaDone
  default_states = { " ", "x" },

  -- 默认键位（也可在 lazy spec keys 里绑）
  keymaps = {
    capture = "<leader>mc",
    agenda = "<leader>ma",
    agenda_done = "<leader>md",
  },
})
```

## 命令

| 命令 | 行为 |
|---|---|
| `:MdCapture` | 弹模板选择，渲染后追加到 capture_file |
| `:MdAgenda` | `show(filter_by_states(collect(), " "))` — 所有待办 |
| `:MdAgendaDone` | `show(filter_by_states(collect(), "x"))` — 已完成 |

## API

```lua
local M = require("md-agenda")

local all    = M.collect()                       -- 扫所有顶级带 ts 的 task block
local todos  = M.filter_by_states(all, " ")      -- 仅保留 state ∈ " " 的
local active = M.filter_active(todos, "2026-08-01", "2026-08-07")  -- [begin,end] 内活跃
M.show(active)
```

| 函数 | 说明 |
|---|---|
| `collect()` | 异步 rg 扫 `scan_dirs`，解析所有顶级 task block，返回 items |
| `filter_by_states(items, states)` | 仅保留 state ∈ `states`（字符串，每个字符一个状态） |
| `exclude_by_states(items, states)` | 排除 state ∈ `states` |
| `filter_active(items, begin, end)` | 保留活跃窗口 ∩ `[begin, end]` ≠ ∅ 的（闭-闭，天粒度，ISO `"YYYY-MM-DD"`） |
| `show(items)` | snacks.picker 渲染，`<CR>` 跳转 file:lnum:col |

### 活跃窗口规则

| when 形式 | 活跃窗口 | 在 `[begin, end]` 内活跃 |
|---|---|---|
| `[]` (always) | `(-∞, ∞)` | 恒为 true |
| `[t]` (from) | `[t, ∞)` | `t ≤ end` |
| `[/t]` (until) | `(-∞, t]` | `begin ≤ t` |
| `[s/e]` (range) | `[s, e]` | `s ≤ end ∧ begin ≤ e` |

## Capture 模板占位符

| 占位符 | 行为 |
|---|---|
| `%?` | 渲染后光标停留位置 |
| `%t` | 当前日期 `YYYY-MM-DD` |
| `%T` | 当前时间戳 `YYYY-MM-DDThh:mm:ss` |
| `%^{name}` | 交互式文本输入 |
| `%^{from}` | 交互式日期选择 → `[date]`（可只选日期，不带时间） |
| `%^{until}` | 交互式日期选择 → `[/date]` |
| `%^{range}` | 两次交互式日期选择 → `[start/stop]` |

### Capture 追加规则

- 解析 `capture_file` 的 strftime 模板（每次 capture 时现算，避免跨午夜失效）
- 不存在则建父目录 + 文件
- 追加到文件末尾，保证与最后非空行间留一个空行，末尾保留一个空行

## 依赖

- Neovim 0.10+
- [snacks.nvim](https://github.com/folke/snacks.nvim)（picker / input）
- [ripgrep](https://github.com/BurntSushi/ripgrep)

## License

MIT