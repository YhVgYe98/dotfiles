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
    :opts {:ensure_installed ["markdown" "markdown_inline"]}))

;;;;;;;;;; markdown-preview ;;;;;;;;;;;;;;
;; 浏览器实时预览 (同步滚动, KaTeX, Mermaid, PlantUML)
;; Vimscript 风格插件, 通过 vim.g 配置, 无 setup()
(set vim.g.mkdp_auto_start 0)       ; 进入 markdown buffer 不自动开预览, 用 :MarkdownPreview 手动触发
(set vim.g.mkdp_auto_close 1)       ; 离开 markdown buffer 自动关预览
(set vim.g.mkdp_refresh_slow 0)     ; 0=实时刷新; 1=保存/离开 insert 才刷新
(set vim.g.mkdp_theme "dark")       ; 匹配 catppuccin-mocha
(set vim.g.mkdp_echo_preview_url 1) ; 命令行 echo 预览 URL — WSL2/远程下浏览器可能无法自动打开, 可手动复制

(table.insert PKG (mt
    ["iamcco/markdown-preview.nvim"]
    :lazy true
    :ft ["markdown"]
    :cmd ["MarkdownPreview" "MarkdownPreviewStop" "MarkdownPreviewToggle"]
    :build #(do (call-at :lazy :load {:plugins [:markdown-preview.nvim]})
             (. vim.fn :mkdp#util#install))))  ; 下载预编译 binary, 无需 node/yarn

PKG
