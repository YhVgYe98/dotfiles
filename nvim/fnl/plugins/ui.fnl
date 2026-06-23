(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))


(local PKG {})

;;;;;;;;;;;;;; Theme ;;;;;;;;;;;;
(table.insert PKG (mt
    ["catppuccin/nvim"]
    :name "catppuccin"
    :priority 1000
    :lazy false
    :config #(vim.cmd.colorscheme "catppuccin-mocha")))


;;;;;;;;;;;;; Lualine ;;;;;;;;;;;;;
; filetypes 独立的配置可以写入 add_extensions，作为整体配置的增量配置
(table.insert PKG (mt
    ["nvim-lualine/lualine.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts_extend ["add_extensions" "extensions"]
    :opts {:options {:theme "auto"
                     :component_separators "|"
                     :section_separators ""}
           :add_extensions []}
    :config (lambda [_ opts]
        (let [lualine (require :lualine)]
            ;; 1. 全局 opts 初始化
            (lualine.setup opts)
            ;; 2. 有 add_extensions 时才处理
            (when (> (length (or opts.add_extensions [])) 0)
            (let [config (lualine.get_config)
                    defaults (vim.deepcopy config.sections)]
                ;; 3. 遍历每个 add_extensions 条目
                (each [_ ext (ipairs opts.add_extensions)]
                ;; 以默认 sections 为底，ext.sections 覆盖差异
                (let [merged-sections (vim.tbl_deep_extend
                                        "force"
                                        defaults
                                        (or ext.sections {}))]
                    (table.insert (or config.extensions
                                    (do (tset config :extensions []) config.extensions))
                                {:filetypes ext.filetypes
                                :sections merged-sections})))
                ;; 4. 重新 setup
                (lualine.setup config)
                (lualine.refresh {:force true})))))))

;;;;;;;;;;;; Notices ;;;;;;;;;;;;;;;
(table.insert PKG (mt
    ["folke/noice.nvim"]
    :lazy true
    :event "VeryLazy"
    :dependencies ["MunifTanjim/nui.nvim"]
    :opts {:cmdline {:enable true :view "cmdline"}
           :popupmenu {:enable false}
           :messages {:enable true
                      :view "mini"
                      :view_history "split"
                      :view_error "mini"
                      :view_warn "mini"
                      :view_search "mini"}
           :notify {:enable true :view "mini"}
           :commands {:all {:view "split"}
                      :history {:view "split"}
                      :last {:view "mini"}
                      :errors {:view "split"}} 
           :lsp {:progress {:view "mini"} :message {:view "mini"}}
           :presets {:bottom_search false
                     :command_palette false
                     :long_message_to_split true}}))

(table.insert PKG (mt
    ["folke/trouble.nvim"]
    :lazy true
    :cmd ["Trouble"]
    :keys [
        (mt ["<leader>xX"
             "<cmd>Trouble diagnostics toggle<cr>"]
             :desc "Diagnostics (Trouble)")
        (mt ["<leader>xx"
             "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"]
             :desc "Buffer Diagnostics (Trouble)")
        (mt ["<leader>cs"
             "<cmd>Trouble symbols toggle focus=false<cr>"]
             :desc "Symbols (Trouble)")
        (mt ["<leader>cl"
             "<cmd>Trouble lsp toggle focus=false win.position=right<cr>"]
             :desc "LSP Definitions / references / ... (Trouble)")
        (mt ["<leader>xl"
             "<cmd>Trouble loclist toggle<cr>"]
             :desc "Location List (Trouble)")
        (mt ["<leader>xq"
             "<cmd>Trouble qflist toggle<cr>"]
             :desc "Quickfix List (Trouble)")]
    :opts {:focus true}))

(table.insert PKG (mt
    ["nvim-telescope/telescope.nvim"]
    :optional true
    :opts (lambda [_ opts]
            (let [open_with_trouble #(call-at :trouble.sources.telescope :open $...)]
              (set opts.defaults (
                 vim.tbl_deep_extend
                   "force"
                   (or opts.defaults {})
                   {:mappings {
                      :i {"<c-t>" open_with_trouble}
                      :n {"<c-t>" open_with_trouble}}}))))))

PKG
