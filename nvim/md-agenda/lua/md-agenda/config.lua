-- 默认配置 + deep-merge。
local M = {}

M.defaults = {
  -- agenda 扫描的目录列表(rg 递归扫 .md)
  scan_dirs = { "~/notes" },

  -- bulk buffer orphan 新 task 在 :w 时追加到此文件。支持 strftime 模板
  capture_file = "~/notes/journal/%Y-%m-%d.md",

  -- capture 模板。键为标识,值为 {desc=, template=}
  templates = {
    default = {
      desc = "Task",
      template = "# [ ][%^{from}] %?",
    },
  },

  -- 默认状态字符: [1]=todo 用于 :MdAgenda, [2]=done 用于 :MdAgendaDone
  default_states = { " ", "x" },

  -- 浮窗日历: week_start 为 ISO 周起始(1=周一..7=周日), min_step 为分钟步长
  calendar = {
    week_start = 1,
    min_step = 5,
  },

  -- 默认键位
  keymaps = {
    task = "<leader>mt",
    agenda = "<leader>ma",
    agenda_done = "<leader>md",
    set_state = "<leader>mx",
  },
}

M._config = nil

--- deep-merge 两个表(用户覆盖默认)
local function deep_merge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k]) == "table" then
      deep_merge(t1[k], v)
    else
      t1[k] = v
    end
  end
  return t1
end

--- 初始化配置。
--- @param opts table|nil 用户配置
--- @return table  最终配置
function M.setup(opts)
  local cfg = vim.deepcopy(M.defaults)
  if opts then
    deep_merge(cfg, opts)
  end
  M._config = cfg
  return cfg
end

--- 获取当前配置(若未 setup 则返回 defaults 副本)。
--- @return table
function M.get()
  if not M._config then
    M._config = vim.deepcopy(M.defaults)
  end
  return M._config
end

return M