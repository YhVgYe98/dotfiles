(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

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

(vim.api.nvim_create_autocmd "TextYankPost" {
    :desc "Highlight yanked text"
    :callback
        #(vim.highlight.on_yank {
            :timeout 200})})

(vim.api.nvim_create_autocmd "BufReadPost" {
    :desc "Auto restore cursor"
    :group (vim.api.nvim_create_augroup "RestoreCursor" {:clear true})
    :pattern "*"
    :callback
        #(let [mark (vim.api.nvim_buf_get_mark 0 "\"")
               loc (. mark 1)
               lcount (vim.api.nvim_buf_line_count 0)]
           (when (and (> loc 0) (<= loc lcount))
                      (pcall vim.api.nvim_win_set_cursor 0 mark)))})


(vim.api.nvim_create_autocmd "BufWritePre" {
    :desc "Create father dir before write file"
    :group (vim.api.nvim_create_augroup "auto_create_dir" {:clear true})
    :callback
        #(let [dir (vim.fn.expand "<afile>:p:h")]
           (when (= (vim.fn.isdirectory dir) 0)
             (pcall vim.fn.mkdir dir "p")))})

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

(vim.keymap.set "n" "<C-h>" "<C-w>h" {:desc "Window Left"})
(vim.keymap.set "n" "<C-l>" "<C-w>l" {:desc "Window Right"})
(vim.keymap.set "n" "<C-j>" "<C-w>j" {:desc "Window Down"})
(vim.keymap.set "n" "<C-k>" "<C-w>k" {:desc "Window Up"})

(vim.keymap.set "n" "]b" "<cmd>bnext<CR>" {:desc "Next Buffer"})
(vim.keymap.set "n" "[b" "<cmd>bprev<CR>" {:desc "Prev Buffer"})

(vim.keymap.set "v" "<" "<gv" {:desc "Indent Out"})
(vim.keymap.set "v" ">" ">gv" {:desc "Indent In"})
(vim.keymap.set "v" "J" ":m '>+1<CR>gv=gv" {:desc "Move selection down"})
(vim.keymap.set "v" "K" ":m '<-2<CR>gv=gv" {:desc "Move selection up"})
(vim.keymap.set "n" "<A-z>" "<cmd>set wrap!<CR>" {:desc "Toggle line wrap"})
(vim.keymap.set "n" "*" "*N" {:noremap true :silent true})
(vim.keymap.set "n" "#" "#N" {:noremap true :silent true})
