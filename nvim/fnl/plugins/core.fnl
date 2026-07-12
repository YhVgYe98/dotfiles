(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))


(local PKG {})

;; LSP 开关: NVIM_NO_LSP=1 启动时禁用 LSP (远程服务器), 运行时 :LspToggle 切换
;; 用显式 = "1" 判断, 避免 Lua 中 "0"/"" 也为 truthy 的坑
(local lsp-enabled (not (= vim.env.NVIM_NO_LSP "1")))

;;;;;;;;;; which-key ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["folke/which-key.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}
    :keys [(mt ["<leader>?" #(call-at :which-key :show {:global false})]
           :desc "Buffer Local Keymaps (which-key)")]))


;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :lazy false
    :opts_extend ["ensure_installed"]
    :opts {:ensure_installed ["lua" "vim" "c" "fennel" "markdown" "markdown_inline" "yaml" "toml" "json" "json5"]
    :auto_install false
    :highlight true}))


;;;;;;;;;; jump ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["nvim-treesitter/nvim-treesitter-textobjects"]
    :branch "main"
    :lazy true
    :init #(set vim.g.no_plugin_maps true)
    :opts {:select {:lookahead true
                    :selection_modes {"@parameter.outer" "v"
                                      "@function.outer"  "V"}
                    :include_surrounding_whitespace false}
           :move {:set_jumps true}}
    :keys (let [select              #(req-at :nvim-treesitter-textobjects.select :select_textobject)
                goto-next-start     #(req-at :nvim-treesitter-textobjects.move :goto_next_start)
                goto-next-end       #(req-at :nvim-treesitter-textobjects.move :goto_next_end)
                goto-previous-start #(req-at :nvim-treesitter-textobjects.move :goto_previous_start)
                goto-previous-end   #(req-at :nvim-treesitter-textobjects.move :goto_previous_end)
                goto-next           #(req-at :nvim-treesitter-textobjects.move :goto_next)
                goto-previous       #(req-at :nvim-treesitter-textobjects.move :goto_previous)]
            [(mt ["am" #((select) "@function.outer" "textobjects")] :mode [:x :o] :desc "Select function outer")
             (mt ["im" #((select) "@function.inner" "textobjects")] :mode [:x :o] :desc "Select function inner")
             (mt ["ac" #((select) "@class.outer" "textobjects")] :mode [:x :o] :desc "Select class outer")
             (mt ["ic" #((select) "@class.inner" "textobjects")] :mode [:x :o] :desc "Select class inner")
             (mt ["as" #((select) "@local.scope" "locals")] :mode [:x :o] :desc "Select local scope")
             ;; --- goto next start ---
             (mt ["]m" #((goto-next-start) "@function.outer" "textobjects")] :mode [:n :x :o] :desc "Next function start")
             (mt ["]c" #((goto-next-start) "@class.outer" "textobjects")] :mode [:n :x :o] :desc "Next class start")
             (mt ["]o" #((goto-next-start) ["@loop.inner" "@loop.outer"] "textobjects")] :mode [:n :x :o] :desc "Next loop start")
             (mt ["]s" #((goto-next-start) "@local.scope" "locals")] :mode [:n :x :o] :desc "Next scope start")
             (mt ["]z" #((goto-next-start) "@fold" "folds")] :mode [:n :x :o] :desc "Next fold start")
             ;; --- goto next end ---
             (mt ["]M" #((goto-next-end) "@function.outer" "textobjects")] :mode [:n :x :o] :desc "Next function end")
             (mt ["]C" #((goto-next-end) "@class.outer" "textobjects")] :mode [:n :x :o] :desc "Next class end")
             ;; --- goto previous start ---
             (mt ["[m" #((goto-previous-start) "@function.outer" "textobjects")] :mode [:n :x :o] :desc "Previous function start")
             (mt ["[c" #((goto-previous-start) "@class.outer" "textobjects")] :mode [:n :x :o] :desc "Previous class start")
             ;; --- goto previous end ---
             (mt ["[M" #((goto-previous-end) "@function.outer" "textobjects")] :mode [:n :x :o] :desc "Previous function end")
             (mt ["[C" #((goto-previous-end) "@class.outer" "textobjects")] :mode [:n :x :o] :desc "Previous class end")
             ;; --- goto next/previous (closer) ---
             ; (mt ["]d" #((goto-next) "@conditional.outer" "textobjects")] :mode [:n :x :o] :desc "Next conditional (closer)")
             ; (mt ["[d" #((goto-previous) "@conditional.outer" "textobjects")] :mode [:n :x :o] :desc "Previous conditional (closer)")
             ])))

;;;;;;;;;;;;;; directory ;;;;;;;;;;;;;;
(set vim.g.loaded_netrw 1)
(set vim.g.loaded_netrwPlugin 1)
(table.insert PKG (mt
    ["stevearc/oil.nvim"]
    :lazy false
    :dependencies ["nvim-mini/mini.icons" "nvim-tree/nvim-web-devicons"]
    :cmd ["Oil"]
    :keys [(mt ["-" "<cmd>Oil<cr>"] :desc "Open parent directory")]
    :opts {:default_file_explorer true
           :columns ["permissions" "size" "mtime" "icon"]}))

;;;;;;;;;;;;;; diagnostics ;;;;;;;;;;;;;;
(set vim.diagnostic.severity_sort true)
(set vim.diagnostic.update_in_insert false)
(vim.keymap.set :n "[d" vim.diagnostic.goto_prev {:desc "Prev Diagnostic"})
(vim.keymap.set :n "]d" vim.diagnostic.goto_next {:desc "Next Diagnostic"})
(vim.keymap.set :n "gl" #(vim.diagnostic.open_float) {:desc "Show Diagnostic Float"})
(vim.keymap.set :n "<leader>dl" #(vim.diagnostic.setloclist) {:desc "Diagnostic LocList"})
(vim.keymap.set :n "<leader>dq" #(vim.diagnostic.setqflist) {:desc "Diagnostic QuickfixList"})
(vim.keymap.set :n "<leader>lf" vim.lsp.buf.format {:desc "Format file"})

;;;;;;;;;;;;;; LSP ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :lazy true
    :event "VeryLazy"
    :dependencies [(mt ["williamboman/mason.nvim"] :opts {})
                   "neovim/nvim-lspconfig"]
    :opts_extend ["ensure_installed"]
    :opts {:ensure_installed ["lua_ls" "fennel_ls"]
           :automatic_enable lsp-enabled}))


(vim.api.nvim_create_autocmd "LspAttach" {
    :group (vim.api.nvim_create_augroup :UserLspConfig {})
    :callback (lambda [args]
                (if vim.g.lsp_disabled
                    (vim.lsp.stop_client args.data.client_id)
                    (let [bufnr args.buf
                          buf-map (lambda [mode lhs rhs desc]
                                    (vim.keymap.set mode lhs rhs {:buffer bufnr :silent true :desc desc}))]
                      (buf-map :n "gd" vim.lsp.buf.definition "Goto Definition")
                      (buf-map :n "K"  vim.lsp.buf.hover "Hover Documentation")
                      (buf-map :n "<leader>rn" vim.lsp.buf.rename "Rename")
                      (buf-map :n "<leader>ca" vim.lsp.buf.code_action "Code Action")
                      (buf-map :n "gr" #(call-at :snacks.picker :lsp_references) "Goto References"))))})

;;;;;;;;;;;;;; LSP Toggle ;;;;;;;;;;;;;;
;; 运行时手动切换 LSP: :LspToggle 停止/启动所有客户端; 内置 :LspStop/:LspStart 逐 buffer
;; 注意: 以 NVIM_NO_LSP=1 启动时服务器未 enable, :LspToggle 无法启动, 需去掉环境变量重启
(vim.api.nvim_create_user_command "LspToggle"
  (fn []
    (if vim.g.lsp_disabled
        (do
          (set vim.g.lsp_disabled false)
          (vim.cmd "LspStart")
          (vim.notify "LSP: 已启动" vim.log.levels.INFO))
        (do
          (vim.lsp.stop_client (vim.lsp.get_clients))
          (set vim.g.lsp_disabled true)
          (vim.notify "LSP: 已停止 (运行 :LspToggle 重新启动)" vim.log.levels.WARN))))
  {:desc "切换 LSP 开关"})

;;;;;;;;;;;;;; DAP ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["jay-babu/mason-nvim-dap.nvim"]
    :lazy true
    :dependencies [(mt ["williamboman/mason.nvim"] :opts {})]
    :opts_extend ["ensure_installed"]
    :opts {:ensure_installed []}))

(table.insert PKG (mt
    ["mfussenegger/nvim-dap"]
    :lazy true
    :dependencies ["rcarriga/nvim-dap-ui"
                   "nvim-neotest/nvim-nio"
                   "jay-babu/mason-nvim-dap.nvim"]
    :keys [
            (mt ["<F5>" #(call-at :dap :continue)] :mode [:n] :desc "Debug: Start/Continue")
            (mt ["<F10>" #(call-at :dap :step_over)] :mode [:n] :desc "Debug: Step Over")
            (mt ["<F11>" #(call-at :dap :step_into)] :mode [:n] :desc "Debug: Step Into")
            (mt ["<F12>" #(call-at :dap :step_out)] :mode [:n] :desc "Debug: Step Out")
            (mt ["<leader>b" #(call-at :dap :toggle_breakpoint)] :mode [:n] :desc "Debug: Toggle Breakpoint")
            (mt ["<leader>B" #((call-at :dap :set_breakpoint) (vim.fn.input "Breakpoint condition: "))] :mode [:n] :desc "Debug: Set Conditional Breakpoint")
            (mt ["<leader>du" #(call-at :dapui :toggle)] :mode [:n] :desc "Debug: Toggle UI")]
    :config #(let [dap (require :dap)
                    dapui (require :dapui)]
                (dapui.setup)
                (tset dap.listeners.after.event_initialized :dapui_config #(dapui.open))
                (tset dap.listeners.before.event_terminated :dapui_config #(dapui.close))
                (tset dap.listeners.before.event_exited     :dapui_config #(dapui.close))
                (vim.api.nvim_set_hl 0 "DapRed"    {:fg "#f43f5e" :italic false})
                (vim.api.nvim_set_hl 0 "DapYellow" {:fg "#f59e0b" :italic false})
                (vim.api.nvim_set_hl 0 "DapBlue"   {:fg "#3b82f6" :italic false})
                (vim.api.nvim_set_hl 0 "DapGreen"  {:fg "#10b981" :italic false})
                (vim.api.nvim_set_hl 0 "DapGray"   {:fg "#9ca3af" :italic false})
                (vim.fn.sign_define "DapBreakpoint"          {:text ""   :texthl "DapRed"    :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointCondition" {:text ""   :texthl "DapYellow" :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointRejected"  {:text ""   :texthl "DapGray"   :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointPoint"     {:text ""   :texthl "DapBlue"   :linehl "" :numhl ""})
                (vim.fn.sign_define "DapStopped"             {:text "󰀕" :texthl "DapGreen"  :linehl "" :numhl ""}))))

;;;;;;;;;;;;;; 自动补全 ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["L3MON4D3/LuaSnip"]
    :lazy true
    :run "make install_jsregexp"))

(table.insert PKG (mt
    ["hrsh7th/nvim-cmp"]
    :lazy true
    :event "InsertEnter"
    :dependencies ["hrsh7th/cmp-nvim-lsp"
                   "hrsh7th/cmp-buffer"
                   "hrsh7th/cmp-path"
                   "L3MON4D3/LuaSnip"
                   "saadparwaiz1/cmp_luasnip"]
    :config #(let [cmp     (require :cmp)
                   luasnip (require :luasnip)
                   cmp-nvim-lsp (require :cmp_nvim_lsp)]
                (vim.lsp.config "*" {:capabilities (cmp-nvim-lsp.default_capabilities)})
                (cmp.setup {
                  :snippet {:expand #(luasnip.lsp_expand $.body)}
                  :mapping (cmp.mapping.preset.insert {
                    :<C-b>     (cmp.mapping.scroll_docs -4)
                    :<C-f>     (cmp.mapping.scroll_docs 4)
                    :<C-Space> (cmp.mapping.complete)
                    :<CR>      (cmp.mapping.confirm {:select true})
                    :<Tab>   (cmp.mapping
                                 #(if (cmp.visible) (cmp.select_next_item)
                                     (luasnip.expand_or_jumpable) (luasnip.expand_or_jump)
                                     ($))
                               ["i" "s"])
                    :<S-Tab> (cmp.mapping
                                 #(if (cmp.visible) (cmp.select_prev_item)
                                     (luasnip.jumpable -1) (luasnip.jump -1)
                                     ($))
                               ["i" "s"])})
                  :sources (cmp.config.sources [
                    {:name "nvim_lsp"}
                    {:name "luasnip"}
                    {:name "buffer"}
                    {:name "path"}])}))))


;;;;;;;;;;;;;; formatter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/conform.nvim"]
    :lazy true
    :event ["BufWritePost" "BufReadPost"]
    :init #(set vim.o.formatexpr "v:lua.require'conform'.formatexpr()")
    :cmd ["ConformInfo"]
    :opts_extend [:autoformat_fts]
    :opts {
        :autoformat_fts []
        :notify_no_formatters false}
    :config (lambda [_ opts]
        (tset opts :format_on_save
            (lambda [bufnr]
                (let [ft (. vim.bo bufnr :filetype)]
                    (when (vim.tbl_contains opts.autoformat_fts ft)
                        {:timeout_ms 500 :lsp_format "fallback"}))))
        (call-at :conform :setup opts))))


;;;;;;;;;;;;;; linter ;;;;;;;;;;;;;;
;; 每个 filetype 在 :opts 字段编写 :linters_by_ft 配置即可，可以像其他插件一下自动合并
(table.insert PKG (mt
       ["mfussenegger/nvim-lint"]
       :lazy true
       :event ["BufWritePost" "BufReadPost"]
       :opts {
           :events ["BufWritePost" "BufReadPost"]
           :linters_by_ft {}
       }
       :config (lambda [_ opts]
           (let [lint (require :lint)]
               ;; 1. 合并所有 linters_by_ft
               (set lint.linters_by_ft (or opts.linters_by_ft {}))
               ;; 2. 自定义 linter 选项
               (when opts.linters
                 (each [name linter (pairs opts.linters)]
                   (if (and (= (type linter) :table)
                            (= (type (. lint.linters name)) :table))
                       (tset lint.linters name
                             (vim.tbl_deep_extend :force (. lint.linters name) linter))
                       (tset lint.linters name linter))))
               ;; 3. debounce + autocommand
               (let [augroup (vim.api.nvim_create_augroup :nvim-lint {:clear true})
                     events (or opts.events ["BufWritePost" "BufReadPost"])]
                 (var lint-timer nil)
                 (vim.api.nvim_create_autocmd events {
                   :group augroup
                   :callback #(do
                       (when lint-timer (lint-timer:stop))
                       (set lint-timer (vim.uv.new_timer))
                       (lint-timer:start 1000 0 #(do
                           (lint-timer:stop)
                           (vim.schedule #(lint.try_lint)))))}))))))
;;;;;;;;;;;;;; git ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["lewis6991/gitsigns.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}))

;;;;;;;;;;;;;; utils ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["nvim-mini/mini.nvim"]
    :lazy true
    :event "VeryLazy"
    :config #(do
        (call-at :mini.ai :setup)
        (call-at :mini.comment :setup)
        (call-at :mini.surround :setup))))

(table.insert PKG (mt
    ["folke/which-key.nvim"]
    :optional true
    :opts [(mt ["s"] :group "Surround")]))


(table.insert PKG (mt
    ["folke/snacks.nvim"]
    :lazy false
    :priority 900
    :opts {
        :picker {:enable true} :input {:enable true}}
    :keys [
        (mt ["<leader>fb" #(call-at :snacks.picker :buffers)] :desc "Buffers")
        (mt ["<leader>ff" #(call-at :snacks.picker :files)] :desc "Files")
        (mt ["<leader>fg" #(call-at :snacks.picker :grep)] :desc "Grep")
        (mt ["<leader>fr" #(call-at :snacks.picker :recent)] :desc "Recent")
        (mt ["<leader>fk" #(call-at :snacks.picker :keymaps)] :desc "Keymaps")
        (mt ["<leader>fh" #(call-at :snacks.picker :help)] :desc "Help")]))


PKG
