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
    :opts {:ensure_installed ["c" "cpp"]}))

;;;;;;;;;; lsp ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :optional true
    :opts {:ensure_installed ["clangd"]}))

;;;;;;;;;; dap ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["jay-babu/mason-nvim-dap.nvim"]
    :optional true
    :opts {
        :ensure_installed ["codelldb"]
        :handlers {
            :c #(call-at :mason-nvim-dap :default_setup $)
            :cpp #(call-at :mason-nvim-dap :default_setup $)}}))

;;;;;;;;;;;;;; formatter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/conform.nvim"]
    :optional true
    :opts {
        :formatters_by_ft {
            :c ["clang-format"]
            :cpp ["clang-format"]}}))

;;;;;;;;;;;;;; linter ;;;;;;;;;;;;;;
(table.insert PKG (mt
       ["mfussenegger/nvim-lint"]
       :optional true
       :opts {
           :linters_by_ft {
               :c ["clangtidy"]
               :cpp ["clangtidy"]
           }}))
PKG
