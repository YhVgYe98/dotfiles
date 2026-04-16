;;;;;;;;;;;;;; UTILS ;;;;;;;;;;;;;;;;
(lambda set-opts [target ...]
  "apply operator to field of vim.opt/vim.opt_local/vim.opt_global at runtime"
  (let [args [...]
        len (length args)]
    (var i 1)
    (while (<= i len)
      (let [k (. args i)
            next-val (. args (+ i 1))
            val-after-next (. args (+ i 2))]
        (if (and (or (= next-val :append)
                     (= next-val :prepend)
                     (= next-val :remove)
                     (= next-val :get))
                 (<= (+ i 2) len))
            (do
              (: (. target k) next-val val-after-next)
              (set i (+ i 3)))
            (do
              (tset target k next-val)
              (set i (+ i 2))))))))

(lambda mixed-map [...]
  (let [args [...]
        len (length args)]
    (assert (= 0 (% len 2)) "mixed-map: 参数数量必须为偶数")
    (let [out-tbl {}]
      (var i 1)
      (var iota-counter 1)
      (while (< i len)
        (let [k (. args i)
              v (. args (+ i 1))]
          (if (= k :iota)
              (do
                (tset out-tbl iota-counter v)
                (set iota-counter (+ iota-counter 1)))
              (tset out-tbl k v))
          (set i (+ i 2))))
      out-tbl)))

(lambda req-call [mod func ...]
  ((. (require mod) func) ...))

(lambda get-path [tbl path]
  (var curr tbl)
  (each [k (path:gmatch "[^%.]+")]
    (set curr (if (= (type curr) :table) (. curr k) nil)))
  curr)

(lambda req-at [mod path]
  "获取模块中的属性。
   mod: 模块名
   path: 属性路径，如 'field.subfield'"
  (let [m (require mod)]
    (get-path m path)))

(lambda call-at [mod path ...]
  "调用模块中的函数。
   mod: 模块名
   path: 函数路径
   ...: 传递给函数的参数"
  (let [target (req-at mod path)]
    (if (= (type target) :function)
        (target ...)
        (error (.. "The property at " path " is not a function")))))

;;;;;;;;;;;;; SETTINGS ;;;;;;;;;;;;;;;;
(set-opts vim.opt
    :number true
    :relativenumber true
    :scrolloff 4
    :sidescrolloff 4
    :background "dark"
    :termguicolors true
    :cursorline true
    :signcolumn "yes"
    :splitbelow true
    :splitright true
    :tabstop 4
    :softtabstop 4
    :shiftwidth 4
    :shiftround true
    :expandtab true
    :autoindent true
    :wrap true
    :breakindent true
    :whichwrap :append "<,>,[,]"
    :ignorecase true
    :smartcase true
    :clipboard "unnamedplus"
    :mouse "a"
    :backup false
    :writebackup false
    :swapfile false
    :undofile true
    :autoread true
    :updatetime 250
    :timeoutlen 300
    :completeopt "menu,menuone,noselect,noinsert"
    :pumheight 10
    :shortmess :append "c"
    :exrc true)

(vim.cmd "aunmenu PopUp.How-to\\ disable\\ mouse")
(vim.cmd "aunmenu PopUp.-2-")

;;;;;;;;; KEYMAPS ;;;;;;;;;;;
(set vim.g.mapleader " ")
(set vim.g.maplocalleader "\\")

(vim.keymap.set "n" "<C-j>" "j" {:silent true})
(vim.keymap.set "n" "<C-k>" "k" {:silent true})
(vim.keymap.set "n" "j" "v:count == 0 ? 'gj' : 'j'" {:expr true :silent true})
(vim.keymap.set "n" "k" "v:count == 0 ? 'gk' : 'k'" {:expr true :silent true})
(vim.keymap.set "n" "<Up>" "v:count == 0 ? 'gk' : 'k'" {:expr true :silent true})
(vim.keymap.set "n" "<Down>" "v:count == 0 ? 'gj' : 'j'" {:expr true :silent true})
(vim.keymap.set "v" "j" "v:count == 0 ? 'gj' : 'j'" {:expr true :silent true})
(vim.keymap.set "v" "k" "v:count == 0 ? 'gk' : 'k'" {:expr true :silent true})
(vim.keymap.set "v" "<Up>" "v:count == 0 ? 'gk' : 'k'" {:expr true :silent true})
(vim.keymap.set "v" "<Down>" "v:count == 0 ? 'gj' : 'j'" {:expr true :silent true})
(vim.keymap.set "i" "<C-j>" "<C-o>gj" {:silent true})
(vim.keymap.set "i" "<C-k>" "<C-o>gk" {:silent true})
(vim.keymap.set "i" "<C-h>" "<C-o>h" {:silent true})
(vim.keymap.set "i" "<C-l>" "<C-o>l" {:silent true})
(vim.keymap.set "i" "<Up>" "<C-o>gk" {:silent true})
(vim.keymap.set "i" "<Down>" "<C-o>gj" {:silent true})

(vim.keymap.set "i" "jj" "<ESC>" {:silent true})
(vim.keymap.set "n" "<leader>w" vim.cmd.w {:desc "Save"})
(vim.keymap.set "n" "<leader>q" vim.cmd.q {:desc "Quit"})
(vim.keymap.set "n" "<leader>wq" vim.cmd.wq {:desc "Save & Quit"})
(vim.keymap.set "n" "<leader>h" "<cmd>nohlsearch<CR>" {:desc "Clear Highlights"})

(vim.keymap.set "n" "<C-h>" "<C-w>h" {:desc "Window Left"})
(vim.keymap.set "n" "<C-l>" "<C-w>l" {:desc "Window Right"})
(vim.keymap.set "n" "<C-j>" "<C-w>j" {:desc "Window Down"})
(vim.keymap.set "n" "<C-k>" "<C-w>k" {:desc "Window Up"})

(vim.keymap.set "n" "<S-l>" "<cmd>bnext<CR>" {:desc "Next Buffer"})
(vim.keymap.set "n" "<S-h>" "<cmd>bprev<CR>" {:desc "Prev Buffer"})
(vim.keymap.set "n" "<leader>x" "<cmd>bdelete<CR>" {:desc "Close Buffer"})

(vim.keymap.set "v" "<" "<gv" {:desc "Indent Out"})
(vim.keymap.set "v" ">" ">gv" {:desc "Indent In"})
(vim.keymap.set "v" "J" ":m '>+1<CR>gv=gv" {:desc "Move selection down"})
(vim.keymap.set "v" "K" ":m '<-2<CR>gv=gv" {:desc "Move selection up"})
(vim.keymap.set "n" "<A-z>" "<cmd>set wrap!<CR>" {:desc "Toggle line wrap"})
(vim.keymap.set "n" "*" "*N" {:noremap true :silent true})
(vim.keymap.set "n" "#" "#N" {:noremap true :silent true})

(vim.api.nvim_create_autocmd "LspAttach" {
    :group (vim.api.nvim_create_augroup :UserLspConfig {})
    :callback (lambda [args]
                (let [bufnr args.buf
                      buf-map (lambda [mode lhs rhs desc]
                                (vim.keymap.set mode lhs rhs {:buffer bufnr :silent true :desc desc}))]
                  (buf-map :n "gd" vim.lsp.buf.definition "Goto Definition")
                  (buf-map :n "K"  vim.lsp.buf.hover "Hover Documentation")
                  (buf-map :n "<leader>rn" vim.lsp.buf.rename "Rename")
                  (buf-map :n "<leader>ca" vim.lsp.buf.code_action "Code Action")
                  (buf-map :n "gr" "<cmd>Telescope lsp_references<cr>" "Goto References")
                  (buf-map :n "[d" vim.diagnostic.goto_prev "Prev Diagnostic")
                  (buf-map :n "]d" vim.diagnostic.goto_next "Next Diagnostic")
                  (buf-map :n "gl" #(vim.diagnostic.open_float) "Show Diagnostic Float")
                  (buf-map :n "<leader>dl" #(vim.diagnostic.setloclist) "Diagnostic LocList")
                  (buf-map :n "<leader>lf" vim.lsp.buf.format "Format file")))})

;;;;;;;;; PACKAGES ;;;;;;;;;;
(local lazypath
       (.. (vim.fn.stdpath "data") "/lazy/lazy.nvim"))

(if (let [stat_pkg (or vim.uv vim.loop)]
      (not (stat_pkg.fs_stat lazypath)))
    (do
        (local lazyrepo "https://github.com/folke/lazy.nvim.git")
        (local out
               (vim.fn.system ["git" "clone" "--filter=blob:none" "--branch=stable" lazyrepo lazypath]))
        (if (~= vim.v.shell_error 0)
            (do
                (vim.api.nvim_echo
                  [["Failed to clone lazy.nvim:\n" "ErrorMsg"]
                   [out "WarningMsg"]
                   ["\nPress any key to exit..."]]
                  true {})
                (vim.fn.getchar)
                (os.exit 1)))))

(vim.opt.rtp:prepend lazypath)
(local PKG {})

;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "nvim-treesitter/nvim-treesitter"
    :lazy false
    :build ":TSUpdate"
    :branch "main"
    :init #(do
             (let [ensure-installed ["lua" "vim" "c" "python" "fennel" "markdown" "markdown_inline" "latex"]
                 already-installed (req-call :nvim-treesitter.config :get_installed)
                 to-install (-> (vim.iter ensure-installed)
                                (: :filter #(not (vim.tbl_contains already-installed $1)))
                                (: :totable))]
              (when (> (length to-install) 0)
                (req-call :nvim-treesitter :install to-install)))
             (vim.api.nvim_create_autocmd "FileType" {
                :callback #(do (pcall vim.treesitter.start) (set vim.bo.indentexpr "v:lua.require'nvim-treesitter'.indentexpr()"))}))))

;;;;;;;;;;; outline ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "hedyhli/outline.nvim"
    :dependencies ["epheien/outline-treesitter-provider.nvim"]
    :event "VeryLazy"
    :cmd ["Outline" "OutlineOpen"]
    :keys [(mixed-map
             :iota "<leader>o"
             :iota "<cmd>Outline<cr>"
             :desc "Toggle outline")]
    :opts {}
    :config #(call-at :outline :setup
                {:providers {:periority ["lsp" "markdown" "treesitter"]}})))

;;;;;;;;;;;; which-key ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "folke/which-key.nvim"
    :event "VeryLazy"
    :opts {}
    :keys [(mixed-map
        :iota "<leader>?"
        :iota #(call-at :which-key :show {:global false})
        :desc "Buffer Local Keymaps (which-key)")]))

;;;;;;;;;;;;;; UI 增强 ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "catppuccin/nvim"
    :name "catppuccin"
    :priority 1000
    :lazy false
    :config #(vim.cmd.colorscheme "catppuccin-mocha")))

(table.insert PKG (mixed-map
    :iota "nvim-lualine/lualine.nvim"
    :opts {:options {:theme "auto"
                     :component_separators "|"
                     :section_separators ""}}))

(table.insert PKG (mixed-map
    :iota "rcarriga/nvim-notify"
    :opts {:timeout 3000
           :stages "fade"}
    :config (lambda [_ opts]
              (call-at :notify :setup opts)
              (set vim.notify (require :notify)))))

(table.insert PKG (mixed-map
    :iota "folke/noice.nvim"
    :event "VeryLazy"
    :dependencies ["MunifTanjim/nui.nvim" "rcarriga/nvim-notify"]
    :opts {:lsp {:override {
                    :vim.lsp.util.convert_input_to_markdown_lines true
                    :vim.lsp.util.styled_parts true
                    :cmp.entry.get_documentation true}}
           :presets {:bottom_search true
                     :command_palette true
                     :long_message_to_split true
                     :inc_rename false
                     :lsp_doc_border true}}))

;;;;;;;;;;;;;; Telescope ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "nvim-telescope/telescope.nvim"
    :event "VeryLazy"
    :dependencies ["nvim-lua/plenary.nvim"]
    :keys [(mixed-map :iota "<leader>ff" :iota "<cmd>Telescope find_files<cr>" :desc "Find Files")
           (mixed-map :iota "<leader>fg" :iota "<cmd>Telescope live_grep<cr>" :desc "Live Grep")
           (mixed-map :iota "<leader>fb" :iota "<cmd>Telescope buffers<cr>" :desc "Buffers")
           (mixed-map :iota "<leader>fh" :iota "<cmd>Telescope help_tags<cr>" :desc "Help Tags")]
    :opts {}))

;;;;;;;;;;;;;; Nvim-Tree ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "nvim-tree/nvim-tree.lua"
    :event "VeryLazy"
    :keys [(mixed-map :iota "<leader>e" :iota "<cmd>NvimTreeToggle<cr>" :desc "Toggle Explorer")]
    :opts {:view {:relativenumber true}
           :renderer {:group_empty true}
           :git {:enable true :ignore false}
           :filters {:dotfiles false :git_ignored false}
           :sync_root_with_cwd true
           :respect_buf_cwd true
           :update_focused_file {:enable true :update_root true}}))

;;;;;;;;;;;;;; LSP ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "neovim/nvim-lspconfig"
    :event "VeryLazy"
    :dependencies ["williamboman/mason.nvim"
                   "williamboman/mason-lspconfig.nvim"
                   "hrsh7th/cmp-nvim-lsp"]
    :config #(let [lspconfig    (require :lspconfig)
                   capabilities (call-at :cmp_nvim_lsp :default_capabilities)]
                (call-at :mason :setup)
                (call-at :mason-lspconfig :setup
                  {:ensure_installed ["lua_ls" "pyright" "clangd" "fennel_ls"]
                   :handlers [(lambda [server-name]
                                 ((. (. lspconfig server-name) :setup)
                                  {: capabilities}))]}))))

;;;;;;;;;;;;;; DAP ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "mfussenegger/nvim-dap"
    :event "VeryLazy"
    :dependencies ["rcarriga/nvim-dap-ui"
                   "nvim-neotest/nvim-nio"
                   "williamboman/mason.nvim"
                   "jay-babu/mason-nvim-dap.nvim"
                   "nvim-telescope/telescope-dap.nvim"]
    :config #(let [dap   (require :dap)
                    dapui (require :dapui)]
                (call-at :mason :setup)
                (call-at :mason-nvim-dap :setup
                  {:ensure_installed ["python"]
                   :automatic_installation true
                   :handlers {
                     1       (lambda [config]
                               (call-at :mason-nvim-dap :default_setup config))
                     :python (lambda [config]
                               (each [_ c (ipairs config.configurations)]
                                 (set c.justMyCode false))
                               (call-at :mason-nvim-dap :default_setup config))}})
                (dapui.setup)
                (vim.keymap.set "n" "<F5>"  dap.continue        {:desc "Debug: Start/Continue"})
                (vim.keymap.set "n" "<F10>" dap.step_over       {:desc "Debug: Step Over"})
                (vim.keymap.set "n" "<F11>" dap.step_into       {:desc "Debug: Step Into"})
                (vim.keymap.set "n" "<F12>" dap.step_out        {:desc "Debug: Step Out"})
                (vim.keymap.set "n" "<leader>b" dap.toggle_breakpoint {:desc "Debug: Toggle Breakpoint"})
                (vim.keymap.set "n" "<leader>B"
                  #(dap.set_breakpoint (vim.fn.input "Breakpoint condition: "))
                  {:desc "Debug: Set Conditional Breakpoint"})
                (vim.keymap.set "n" "<leader>du" dapui.toggle {:desc "Debug: Toggle UI"})
                (vim.keymap.set "n" "<leader>fb" "<cmd>Telescope dap list_breakpoints<CR>"
                  {:desc "Telescope: View Breakpoints"})
                (tset dap.listeners.after.event_initialized  :dapui_config #(dapui.open))
                (tset dap.listeners.before.event_initialized :dapui_config #(dapui.close))
                (tset dap.listeners.before.event_exited      :dapui_config #(dapui.close))
                (vim.api.nvim_set_hl 0 "DapRed"    {:fg "#f43f5e" :italic false})
                (vim.api.nvim_set_hl 0 "DapYellow" {:fg "#f59e0b" :italic false})
                (vim.api.nvim_set_hl 0 "DapBlue"   {:fg "#3b82f6" :italic false})
                (vim.api.nvim_set_hl 0 "DapGreen"  {:fg "#10b981" :italic false})
                (vim.api.nvim_set_hl 0 "DapGray"   {:fg "#9ca3af" :italic false})
                (vim.fn.sign_define "DapBreakpoint"          {:text ""   :texthl "DapRed"    :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointCondition" {:text ""   :texthl "DapYellow" :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointRejected"  {:text ""   :texthl "DapGray"   :linehl "" :numhl ""})
                (vim.fn.sign_define "DapBreakpointPoint"     {:text ""   :texthl "DapBlue"   :linehl "" :numhl ""})
                (vim.fn.sign_define "DapStopped"             {:text "󰁕" :texthl "DapGreen"  :linehl "" :numhl ""}))))

;;;;;;;;;;;;;; 自动补全 ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "L3MON4D3/LuaSnip"
    :event "VeryLazy"))

;; cmp / luasnip 在配置表内被大量引用（mapping、sources、snippet 等），
;; 保持 let binding 比反复调用 req-at/call-at 更清晰
(table.insert PKG (mixed-map
    :iota "hrsh7th/nvim-cmp"
    :event "VeryLazy"
    :dependencies ["hrsh7th/cmp-nvim-lsp"
                   "hrsh7th/cmp-buffer"
                   "hrsh7th/cmp-path"
                   "L3MON4D3/LuaSnip"
                   "saadparwaiz1/cmp_luasnip"]
    :config #(let [cmp     (require :cmp)
                    luasnip (require :luasnip)]
                (cmp.setup {
                  :snippet {:expand (lambda [args] (luasnip.lsp_expand args.body))}
                  :mapping (cmp.mapping.preset.insert {
                    :<C-b>     (cmp.mapping.scroll_docs -4)
                    :<C-f>     (cmp.mapping.scroll_docs 4)
                    :<C-Space> (cmp.mapping.complete)
                    :<CR>      (cmp.mapping.confirm {:select true})
                    :<Tab>   (cmp.mapping
                               (lambda [fallback]
                                 (if (cmp.visible)              (cmp.select_next_item)
                                     (luasnip.expand_or_jumpable) (luasnip.expand_or_jump)
                                     (fallback)))
                               ["i" "s"])
                    :<S-Tab> (cmp.mapping
                               (lambda [fallback]
                                 (if (cmp.visible)        (cmp.select_prev_item)
                                     (luasnip.jumpable -1) (luasnip.jump -1)
                                     (fallback)))
                               ["i" "s"])})
                  :sources (cmp.config.sources [
                    {:name "nvim_lsp"}
                    {:name "luasnip"}
                    {:name "buffer"}
                    {:name "path"}])}))))

;;;;;;;;;;;;;; 其它实用工具 ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map :iota "lewis6991/gitsigns.nvim" :event "VeryLazy" :opts {}))

;;;;;;;;;;;;; FILETYPE PLUGINS ;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "lervag/vimtex"
    :lazy false
    :init #(set vim.g.vimtex_view_method "general")))

;;;;;;;;;; install all packages ;;;;;;;;;;;
(call-at :lazy :setup
  {:spec    PKG
   :install {:colorscheme ["habamax"]}
   :checker {:enable true}})
