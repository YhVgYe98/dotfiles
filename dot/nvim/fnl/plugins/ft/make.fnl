(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local PKG {})


;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :optional true
    :opts {:ensure_installed ["make"]}))

PKG
