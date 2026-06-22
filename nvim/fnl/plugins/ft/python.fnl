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
    :opts {:ensure_installed ["python"]}))

;;;;;;;;;; lsp ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :optional true
    :opts {:ensure_installed ["ruff"]}))

;;;;;;;;;; dap ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["jay-babu/mason-nvim-dap.nvim"]
    :optional true
    :opts {
        :ensure_installed ["python"]
        :handlers {
            :python #(do
                        (each [_ c (ipairs $.configurations)]
                            (set c.justMyCode false))
                        (call-at :mason-nvim-dap :default_setup $))}}))

PKG
