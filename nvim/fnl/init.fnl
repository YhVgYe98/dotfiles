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

(lambda mt [arr ...]
    (let [keys [...]
        n (length keys)]
        (assert (= 0 (% n 2)) "参数数量必须为偶数")
        (for [i 1 n 2]
            (tset arr (. keys i) (. keys (+ i 1))))
        arr))


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
    :exrc true
    :list true
    :listchars {:tab "»-" :trail "·" :nbsp "␣"})

(vim.cmd "aunmenu PopUp.How-to\\ disable\\ mouse")
(vim.cmd "aunmenu PopUp.-2-")

;;;;;;;;; KEYMAPS ;;;;;;;;;;;
(set vim.g.mapleader " ")
(set vim.g.maplocalleader "\\")

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

;;;;;;;;;;;; which-key ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["folke/which-key.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}
    :keys [(mt ["<leader>?" #(call-at :which-key :show {:global false})]
           :desc "Buffer Local Keymaps (which-key)")]))

;;;;;;;;;;;;;; UI ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["catppuccin/nvim"]
    :name "catppuccin"
    :priority 1000
    :lazy false
    :config #(vim.cmd.colorscheme "catppuccin-mocha")))

(table.insert PKG (mt
    ["nvim-lualine/lualine.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {:options {:theme "auto"
                     :component_separators "|"
                     :section_separators ""}}))

(table.insert PKG (mt
    ["folke/noice.nvim"]
    :lazy true
    :event "VeryLazy"
    :dependencies ["MunifTanjim/nui.nvim"]
    :opts {:cmdline {:enable true :view "cmdline"}
           :popupmenu {:enable false}
           :messages {:enable true
                      :view "mini"
                      :view_history "split"
                      :view_error "mini"
                      :view_warn "mini"
                      :view_search "mini"}
           :notify {:enable true :view "mini"}
           :commands {:all {:view "split"}
                      :history {:view "split"}
                      :last {:view "mini"}
                      :errors {:view "split"}} 
           :lsp {:progress {:view "mini"} :message {:view "mini"}}
           :presets {:bottom_search false
                     :command_palette false
                     :long_message_to_split true}}))

;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :lazy false
    :opts {:ensure_installed ["lua" "vim" "c" "python" "fennel" "markdown" "markdown_inline" "latex"]
    :auto_install false
    :highlight true}))


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
             (mt ["]d" #((goto-next) "@conditional.outer" "textobjects")] :mode [:n :x :o] :desc "Next conditional (closer)")
             (mt ["[d" #((goto-previous) "@conditional.outer" "textobjects")] :mode [:n :x :o] :desc "Previous conditional (closer)")])))

;;;;;;;;;;;;;; Telescope ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["nvim-telescope/telescope.nvim"]
    :lazy true
    :version "*"
    :dependencies ["nvim-lua/plenary.nvim"
                   (mt ["nvim-telescope/telescope-fzf-native.nvim"] :build "make")
                   "nvim-tree/nvim-web-devicons"]
    :cmd ["Telescope"]
    :keys [(mt ["<leader>ff" "<cmd>Telescope find_files<cr>"] :desc "Find Files")
           (mt ["<leader>fg" "<cmd>Telescope live_grep<cr>"] :desc "Live Grep")
           (mt ["<leader>fb" "<cmd>Telescope buffers<cr>"] :desc "Buffers")
           (mt ["<leader>fh" "<cmd>Telescope help_tags<cr>"] :desc "Help Tags")]
    :opts {:defaults {:layout_strategy "vertical"
                      :layout_config {:width 0.5 :preview_cutoff 1 :prompt_position "bottom"}
                      :scroll_strategy "cycle"}}))

;;;;;;;;;;;;;; directory ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/oil.nvim"]
    :lazy true
    :dependencies ["nvim-mini/mini.icons" "nvim-tree/nvim-web-devicons"]
    :cmd ["Oil"]
    :keys [(mt ["-" "<cmd>Oil<cr>"] :desc "Open parent directory")]
    :opts {:default_file_explorer true
           :columns ["permissions" "size" "mtime" "icon"]}))

;;;;;;;;;;;;;; LSP ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :lazy true
    :event "VeryLazy"
    :dependencies [(mt ["williamboman/mason.nvim"] :opts {})
                   "neovim/nvim-lspconfig"]
    :opts {:ensure_installed ["lua_ls" "pyright" "clangd" "fennel_ls"]}))


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
                  (buf-map :n "gr" #(call-at :telescope.builtin :lsp_references) "Goto References")
                  (buf-map :n "[d" vim.diagnostic.goto_prev "Prev Diagnostic")
                  (buf-map :n "]d" vim.diagnostic.goto_next "Next Diagnostic")
                  (buf-map :n "gl" #(vim.diagnostic.open_float) "Show Diagnostic Float")
                  (buf-map :n "<leader>dl" #(vim.diagnostic.setloclist) "Diagnostic LocList")
                  (buf-map :n "<leader>lf" vim.lsp.buf.format "Format file")))})

;;;;;;;;;;;;;; DAP ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["jay-babu/mason-nvim-dap.nvim"]
    :lazy true
    :dependencies [(mt ["williamboman/mason.nvim"] :opts {})]
    :opts {
        :ensure_installed ["python"]
        :automatic_installation true
        :handlers (mt
            [#(call-at :mason-nvim-dap :default_setup $)]
            :python #(do
                        (each [_ c (ipairs $.configurations)]
                            (set c.justMyCode false))
                        (call-at :mason-nvim-dap :default_setup $)))}))

(table.insert PKG (mt
    ["mfussenegger/nvim-dap"]
    :lazy true
    :dependencies ["rcarriga/nvim-dap-ui"
                   "nvim-neotest/nvim-nio"
                   "jay-babu/mason-nvim-dap.nvim"
                   "nvim-telescope/telescope-dap.nvim"
                   "nvim-telescope/telescope.nvim"]
    :keys [
            (mt ["<F5>" #(call-at :dap :continue)] :mode [:n] :desc "Debug: Start/Continue")
            (mt ["<F10>" #(call-at :dap :step_over)] :mode [:n] :desc "Debug: Step Over")
            (mt ["<F11>" #(call-at :dap :step_into)] :mode [:n] :desc "Debug: Step Into")
            (mt ["<F12>" #(call-at :dap :step_out)] :mode [:n] :desc "Debug: Step Out")
            (mt ["<leader>b" #(call-at :dap :toggle_breakpoint)] :mode [:n] :desc "Debug: Toggle Breakpoint")
            (mt ["<leader>B" #((call-at :dap :set_breakpoint) (vim.fn.input "Breakpoint condition: "))] :mode [:n] :desc "Debug: Set Conditional Breakpoint")
            (mt ["<leader>du" #(call-at :dapui :toggle)] :mode [:n] :desc "Debug: Toggle UI")
            (mt ["<leader>fb" #(call-at :telescope.dap :list_breakpoints)] :mode [:n] :desc "Telescope: View Breakpoints")]
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
                (vim.fn.sign_define "DapStopped"             {:text "󰁕" :texthl "DapGreen"  :linehl "" :numhl ""}))))

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
                    luasnip (require :luasnip)]
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

;;;;;;;;;;;;;; 其它实用工具 ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["lewis6991/gitsigns.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}))

;;;;;;;;;;;;; FILETYPE PLUGINS ;;;;;;;;;;;;;
(table.insert PKG (mt
    ["lervag/vimtex"]
    :lazy true
    :ft ["tex" "plaintex" "bib"]
    :init #(set vim.g.vimtex_view_method "general")))

;;;;;;;;;; install all packages ;;;;;;;;;;;
(call-at :lazy :setup
  {:spec    PKG
   :install {:colorscheme ["habamax"]}
   :checker {:enable true}})
