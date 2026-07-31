(local {
    : set-opts
    : mt
    : req-at
    : call-at}
 (require :utils))

(local PKG {})

(table.insert PKG (mt
    ["md-agenda"]
    :dir (.. (vim.fn.stdpath :config) "/md-agenda")
    :cmd ["MdCapture" "MdAgenda" "MdAgendaDone"]
    :opts {:scan_dirs ["~/notes"]
           :capture_file "~/notes/journal/%Y-%m-%d.md"}
    :keys [(mt ["<leader>mc" "<cmd>MdCapture<cr>"] :desc "Capture task")
           (mt ["<leader>ma" "<cmd>MdAgenda<cr>"] :desc "Agenda (todo)")
           (mt ["<leader>md" "<cmd>MdAgendaDone<cr>"] :desc "Agenda (done)")]))

PKG
