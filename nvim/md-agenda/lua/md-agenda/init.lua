-- 入口: setup + 命令注册 + 公共 API 导出。
local M = {}

local config = require("md-agenda.config")
local agenda = require("md-agenda.agenda")
local capture_mod = require("md-agenda.capture")
local edit = require("md-agenda.edit")
local ui = require("md-agenda.ui")

--- 初始化插件。
--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)

  -- 命令注册
  local states = config.get().default_states or { " ", "x" }
  vim.api.nvim_create_user_command("MdCapture", function() M.capture() end, { desc = "Capture task" })
  vim.api.nvim_create_user_command("MdAgenda", function()
    M.show(M.filter_by_states(M.collect(), states[1] or " "))
  end, { desc = "Agenda (todo)" })
  vim.api.nvim_create_user_command("MdAgendaDone", function()
    M.show(M.filter_by_states(M.collect(), states[2] or "x"))
  end, { desc = "Agenda (done)" })

  -- 默认键位
  local keymaps = config.get().keymaps or {}
  if keymaps.capture then
    vim.keymap.set("n", keymaps.capture, "<cmd>MdCapture<cr>", { desc = "Capture task" })
  end
  if keymaps.agenda then
    vim.keymap.set("n", keymaps.agenda, "<cmd>MdAgenda<cr>", { desc = "Agenda (todo)" })
  end
  if keymaps.agenda_done then
    vim.keymap.set("n", keymaps.agenda_done, "<cmd>MdAgendaDone<cr>", { desc = "Agenda (done)" })
  end
  if keymaps.set_state then
    vim.keymap.set("n", keymaps.set_state, function() M.set_state("x", true) end, { desc = "Mark done (md-agenda)" })
  end
end

-- 公共 API
M.collect = agenda.collect
M.filter_by_states = agenda.filter_by_states
M.exclude_by_states = agenda.exclude_by_states
M.filter_active = agenda.filter_active
M.show = ui.show
M.capture = capture_mod.capture
M.set_state = edit.set_state

return M