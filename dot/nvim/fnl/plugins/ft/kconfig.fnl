(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local PKG {})

;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
;; Neovim 已内置 Kconfig filetype 检测 (Kconfig, Kconfig.*, Config.in 等)，
;; 无需 vim.filetype.add，此处仅安装 treesitter parser
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :optional true
    :opts {:ensure_installed ["kconfig"]}))

PKG
