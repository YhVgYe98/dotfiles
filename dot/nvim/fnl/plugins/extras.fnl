(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))


(local PKG {})

;;;;;;;;;; which-key ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["folke/which-key.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}
    :keys [(mt ["<leader>?" #(call-at :which-key :show {:global false})]
           :desc "Buffer Local Keymaps (which-key)")]))

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

;;;;;;;;;;;;;; img-clip ;;;;;;;;;;;;;;
;; 从系统剪贴板粘贴图片, 自动存文件 + 插入链接模板
;; 支持 markdown / org / tex / typst / html 等 (内置默认模板, 无需逐个配置)
(table.insert PKG (mt
    ["HakonHarnes/img-clip.nvim"]
    :lazy true
    :opts {:default {:dir_path "assets"                     ; 图片保存目录 (相对当前文件)
                     :file_name "%Y-%m-%d-%H-%M-%S"         ; 时间戳文件名
                     :relative_to_current_file true         ; dir_path 相对当前文件而非 cwd
                     :prompt_for_file_name false}}          ; 不提示输入文件名, 用时间戳
    :keys [(mt ["<leader>pi" "<cmd>PasteImage<cr>"] :desc "Paste image from clipboard")]))

PKG
