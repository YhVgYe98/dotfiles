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


;;;;;;;;;;;;; SETTINGS ;;;;;;;;;;;;;;;;
(set-opts vim.opt
    :number true
    :relativenumber true
    :scrolloff 4
    :sidescrolloff 4
    :background "dark"
    :termguicolors true
    :cursorline true ; 高亮当前行
    :signcolumn "yes"

    :splitbelow true
    :splitright true

    :tabstop 4
    :softtabstop 4
    :shiftwidth 4
    :shiftround true
    :expandtab true
    :autoindent true

    :wrap true              ; 折行
    :breakindent true       ; 折行保持缩进
    :whichwrap :append "<,>,[,]"

    :ignorecase true
    :smartcase true

    :clipboard "unnamedplus"    ; 共享 */+ 两种剪贴板; make boot slow in wsl
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
    :shortmess :append "c")

;;;;;;;;; KEYMAPS ;;;;;;;;;;;
(set vim.g.mapleader " ")
(set vim.g.maplocalleader "\\")
;; 1. 基础操作
(vim.keymap.set "i" "jj" "<ESC>" {:silent true})
(vim.keymap.set "n" "<leader>w" vim.cmd.w {:desc "Save"})
(vim.keymap.set "n" "<leader>q" vim.cmd.q {:desc "Quit"})
(vim.keymap.set "n" "<leader>wq" vim.cmd.wq {:desc "Save & Quit"})
(vim.keymap.set "n" "<leader>h" "<cmd>nohlsearch<CR>" {:desc "Clear Highlights"})
;; 2. 窗口导航 (Ctrl + hjkl)
(vim.keymap.set "n" "<C-h>" "<C-w>h" {:desc "Window Left"})
(vim.keymap.set "n" "<C-l>" "<C-w>l" {:desc "Window Right"})
(vim.keymap.set "n" "<C-j>" "<C-w>j" {:desc "Window Down"})
(vim.keymap.set "n" "<C-k>" "<C-w>k" {:desc "Window Up"})
;; 3. Buffer 导航 (Shift + h/l)
(vim.keymap.set "n" "<S-l>" "<cmd>bnext<CR>" {:desc "Next Buffer"})
(vim.keymap.set "n" "<S-h>" "<cmd>bprev<CR>" {:desc "Prev Buffer"})
(vim.keymap.set "n" "<leader>x" "<cmd>bdelete<CR>" {:desc "Close Buffer"})
;; 4. 视觉模式调整
;; 缩进后保持选中状态
(vim.keymap.set "v" "<" "<gv" {:desc "Indent Out"})
(vim.keymap.set "v" ">" ">gv" {:desc "Indent In"})
;; 移动选中的行
(vim.keymap.set "v" "J" ":m '>+1<CR>gv=gv" {:desc "Move selection down"})
(vim.keymap.set "v" "K" ":m '<-2<CR>gv=gv" {:desc "Move selection up"})

(vim.api.nvim_create_autocmd "LspAttach" {
    :group (vim.api.nvim_create_augroup :UserLspConfig {})
    :callback (fn [args]
                (let [bufnr args.buf
                      ;; 定义快捷键辅助函数
                      buf-map (fn [mode lhs rhs desc]
                                (vim.keymap.set mode lhs rhs {:buffer bufnr :silent true :desc desc}))]
                  
                  ;; 在这里定义你所有的 LSP 快捷键
                  (buf-map :n "gd" vim.lsp.buf.definition "Goto Definition")
                  (buf-map :n "K"  vim.lsp.buf.hover "Hover Documentation")
                  (buf-map :n "<leader>rn" vim.lsp.buf.rename "Rename")
                  (buf-map :n "<leader>ca" vim.lsp.buf.code_action "Code Action")
                  (buf-map :n "gr" "<cmd>Telescope lsp_references<cr>" "Goto References")
                  
                  (buf-map :n "[d" vim.diagnostic.goto_prev "Prev Diagnostic")
                  (buf-map :n "]d" vim.diagnostic.goto_next "Next Diagnostic")
                  (buf-map :n "gl" (fn [] (vim.diagnostic.open_float)) "Show Diagnostic Float")
                  (buf-map :n "<leader>dl" (fn [] (vim.diagnostic.setloclist)) "Diagnostic LocList")))})

;;;;;;;;; PACKAGES ;;;;;;;;;;
;;;;;;;;;; package manager ;;;;;;;;;;;
(local lazypath
       (.. (vim.fn.stdpath "data")
           "/lazy/lazy.nvim"))

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

; below wrote by gemimi
;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
;; TODO 切换到 main 分支
(table.insert PKG (mixed-map
    :iota "nvim-treesitter/nvim-treesitter"
    :lazy false
    :build ":TSUpdate"
    :branch "master"
    :opts {:highlight {:enable true}
           :indent {:enable true}
           :ensure_installed ["lua" "vim" "c" "python" "fennel" "markdown" "markdown_inline" "latex"]}
    :config (lambda [_ opts] 
              (let [setup (. (require :nvim-treesitter.configs) :setup)]
                (setup opts)))))

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
    :config (lambda []
              (let [setup (. (require :outline) :setup)]
                    (setup {:providers {:periority ["lsp" "markdown" "treesitter"]}})))))


;;;;;;;;;;;; which key ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "folke/which-key.nvim"
    :event "VeryLazy"
    :opts {}
    :keys [(mixed-map
        :iota "<leader>?"
        :iota (lambda [] ((. (require :which-key) :show) {:global false}))
        :desc "Buffer Local Keymaps (which-key)")]))

;;;;;;;;;;;;;; UI 增强 ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "catppuccin/nvim"
    :name "catppuccin"
    :priority 1000
    :config (lambda [] 
              (vim.cmd.colorscheme "catppuccin-mocha"))))
(table.insert PKG (mixed-map
    :iota "nvim-lualine/lualine.nvim"
    :opts {:options {:theme "catppuccin"
                     :component_separators "|"
                     :section_separators ""}}))
(table.insert PKG (mixed-map
    :iota "rcarriga/nvim-notify"
    :opts {:timeout 3000
           :stages "fade"}
    :config (lambda [_ opts]
              (let [notify (require :notify)]
                (notify.setup opts)
                ;; 覆盖默认的 vim.notify
                (set vim.notify notify)))))
;; 弹出式命令行、搜索栏及 UI 界面重构
(table.insert PKG (mixed-map
    :iota "folke/noice.nvim"
    :event "VeryLazy"
    :dependencies ["MunifTanjim/nui.nvim" "rcarriga/nvim-notify"]
    :opts {:lsp {:override {
                    :vim.lsp.util.convert_input_to_markdown_lines true
                    :vim.lsp.util.styled_parts true
                    :cmp.entry.get_documentation true}}
           :presets {:bottom_search true         ; 搜索栏移到下方（可选）
                     :command_palette true      ; 启用弹出式命令行
                     :long_message_to_split true ; 长消息转入 split
                     :inc_rename false          ; 启用增量重命名对话框
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
           :filters {:dotfiles false}
           :sync_root_with_cwd true
           :respect_buf_cwd true
           :update_focused_file {:enable true :update_root true}}))
;;;;;;;;;;;;;; LSP 配置 (Mason & LSPConfig) ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "neovim/nvim-lspconfig"
    :event "VeryLazy"
    :dependencies ["williamboman/mason.nvim" 
                   "williamboman/mason-lspconfig.nvim"
                   "hrsh7th/cmp-nvim-lsp"]
    :config (lambda []
              (let [mason (require :mason)
                    mason-lsp (require :mason-lspconfig)
                    lspconfig (require :lspconfig)
                    capabilities ((. (require :cmp_nvim_lsp) :default_capabilities))]
                (mason.setup)
                (mason-lsp.setup {
                    :ensure_installed ["lua_ls" "pyright" "clangd" "fennel_ls"]
                    :handlers [
                        (fn [server-name]
                            ((. (. lspconfig server-name) :setup) {: capabilities}))]})))))

;;;;;;;;;;;;;; 自动补全 ;;;;;;;;;;;;;;
(table.insert PKG (mixed-map
    :iota "L3MON4D3/LuaSnip"
    :event "VeryLazy"))


(table.insert PKG (mixed-map
    :iota "hrsh7th/nvim-cmp"
    :event "VeryLazy"
    :dependencies ["hrsh7th/cmp-nvim-lsp" 
                   "hrsh7th/cmp-buffer" 
                   "hrsh7th/cmp-path"
                   "L3MON4D3/LuaSnip"
                   "saadparwaiz1/cmp_luasnip"]
    :config (lambda []
              (let [cmp (require :cmp)
                    luasnip (require :luasnip)]
                (cmp.setup {
                  :snippet {:expand (fn [args] (luasnip.lsp_expand args.body))}
                  :mapping (cmp.mapping.preset.insert {
                    :<C-b> (cmp.mapping.scroll_docs -4)
                    :<C-f> (cmp.mapping.scroll_docs 4)
                    :<C-Space> (cmp.mapping.complete)
                    :<CR> (cmp.mapping.confirm {:select true})
                    :<Tab> (cmp.mapping (fn [fallback]
                                          (if (cmp.visible) (cmp.select_next_item)
                                              (luasnip.expand_or_jumpable) (luasnip.expand_or_jump)
                                              (fallback))) ["i" "s"])
                    :<S-Tab> (cmp.mapping (fn [fallback]
                                            (if (cmp.visible) (cmp.select_prev_item)
                                                (luasnip.jumpable -1) (luasnip.jump -1)
                                                (fallback))) ["i" "s"])})
                  :sources (cmp.config.sources [
                    {:name "nvim_lsp"}
                    {:name "luasnip"}
                    {:name "buffer"}
                    {:name "path"}])})))))


;;;;;;;;;;;;;; 其它实用工具 ;;;;;;;;;;;;;;
;; 自动配对括号
(table.insert PKG (mixed-map :iota "windwp/nvim-autopairs" :event "InsertEnter" :opts {}))
;; Git 状态
(table.insert PKG (mixed-map :iota "lewis6991/gitsigns.nvim" :event "VeryLazy" :opts {}))


;;;;;;;;;; install all packages ;;;;;;;;;;;
(let [setup (. (require :lazy) :setup)]
  (setup {
    :spec    PKG
    :install {:colorscheme ["habamax"]}
    :checker {:enable true}}))

