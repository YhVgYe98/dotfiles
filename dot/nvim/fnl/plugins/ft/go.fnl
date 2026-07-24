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
    :opts {:ensure_installed ["go"]}))

;;;;;;;;;; lsp ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :optional true
    :opts {:ensure_installed ["gopls"]}))

;;;;;;;;;;;;;; formatter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/conform.nvim"]
    :optional true
    :opts {
        :autoformat_fts ["go"]
        :formatters_by_ft {
            :go ["gofumpt"]}}))

;;;;;;;;;;;;;; linter ;;;;;;;;;;;;;;
(table.insert PKG (mt
       ["mfussenegger/nvim-lint"]
       :optional true
       :opts {
           :linters_by_ft {
               :go ["golangcilint"]
           }}))
PKG
