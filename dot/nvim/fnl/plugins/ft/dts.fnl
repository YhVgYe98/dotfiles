(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local PKG {})

;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
;; devicetree parser 自动映射 dts filetype (含 .dts/.dtsi)
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :optional true
    :opts {:ensure_installed ["devicetree"]}))

PKG
