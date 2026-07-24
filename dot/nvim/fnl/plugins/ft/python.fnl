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

;;;;;;;;;; venv-selector ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["linux-cultist/venv-selector.nvim"]
    :dependencies ["folke/snacks.nvim"]
    :lazy true
    :ft "python"
    :cmd "VenvSelect"
    :keys [(mt ["<localleader>vs"] :ft "python" :desc "Select Python venv")]
    :opts {}))

;;;;;;;;;;;; Lualine ;;;;;;;;;;;;
(table.insert PKG (mt
    ["nvim-lualine/lualine.nvim"]
    :optional true
    :opts {
        :add_extensions [{
            :filetypes ["python"]
            :sections {
                :lualine_x ["encoding" "fileformat" "venv-selector" "filetype"]}}]}))
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

;;;;;;;;;;;;;; formatter ;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["stevearc/conform.nvim"]
    :optional true
    :opts {
        :formatters_by_ft {
            :python ["ruff_format"]}}))

;;;;;;;;;;;;;; linter ;;;;;;;;;;;;;;
(table.insert PKG (mt
       ["mfussenegger/nvim-lint"]
       :optional true
       :opts {
           :linters_by_ft {
               :python ["ruff"]
           }}))
PKG
