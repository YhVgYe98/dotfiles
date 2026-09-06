(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local PKG {})

;;;;;;;;;; treesitter ;;;;;;;;;;;;;;
;; javascript/typescript parser 覆盖 .js/.jsx/.ts/.tsx 四种 filetype
(table.insert PKG (mt
    ["romus204/tree-sitter-manager.nvim"]
    :optional true
    :opts {:ensure_installed ["javascript" "typescript"]}))

;;;;;;;;;; lsp ;;;;;;;;;;;;;;
;; ts_ls: typescript-language-server; eslint: ESLint 的 LSP 服务器 (mason 包名 eslint-lsp)
;; lint 诊断由 eslint-lsp 通过 LSP diagnostics 提供, 不再依赖 nvim-lint(命令行 eslint)
(table.insert PKG (mt
    ["williamboman/mason-lspconfig.nvim"]
    :optional true
    :opts {:ensure_installed ["ts_ls" "eslint"]}))

;;;;;;;;;;;;;; formatter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/conform.nvim"]
    :optional true
    :opts {
        :autoformat_fts ["javascript" "javascriptreact" "typescript" "typescriptreact"]
        :formatters_by_ft {
            :javascript ["prettier"]
            :javascriptreact ["prettier"]
            :typescript ["prettier"]
            :typescriptreact ["prettier"]}}))

;; 注: 无 nvim-lint 段 —— JS/TS 的 lint 由 eslint-lsp 的 LSP diagnostics 提供
PKG
