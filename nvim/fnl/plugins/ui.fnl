(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))


(local PKG {})

(table.insert PKG (mt
    ["folke/which-key.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {}
    :keys [(mt ["<leader>?" #(call-at :which-key :show {:global false})]
           :desc "Buffer Local Keymaps (which-key)")]))

(table.insert PKG (mt
    ["catppuccin/nvim"]
    :name "catppuccin"
    :priority 1000
    :lazy false
    :config #(vim.cmd.colorscheme "catppuccin-mocha")))

(table.insert PKG (mt
    ["nvim-lualine/lualine.nvim"]
    :lazy true
    :event "VeryLazy"
    :opts {:options {:theme "auto"
                     :component_separators "|"
                     :section_separators ""}}))

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
