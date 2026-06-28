(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local PKG {})

(table.insert PKG (mt
    ["nvim-orgmode/orgmode"]
    :lazy true
    :cmd ["Org"]
    :ft ["org"]
    :keys [
        (mt ["<leader>oa" "<cmd>Org agenda<CR>"]   :desc "Agenda")
        (mt ["<leader>oc" "<cmd>Org capture<CR>"]  :desc "Capture")
    ]
    :opts {
        :org_agenda_files "~/org/**/*"
        :win_split_mode "vertical"
        :org_agenda_span "week"
        :org_agenda_skip_scheduled_if_done true
        :org_agenda_skip_deadline_if_done true
        :org_agenda_skip_if_done true
        :org_default_notes_file "~/org/refile.org"
        :org_startup_indented true
        :org_startup_folded "showeverything"
        :org_todo_keywords ["TODO(t)" "NEXT(n)" "WAIT(w)" "|" "DONE(d)" "CANCEL(c)"]
        :org_confirm_before_closing false
        :org_capture_templates {
            :t {:description "Todo"
                :template "* TODO %?\n  %^{Begin date}t\n  %U"
                :target "~/org/journal/%<%Y-%m-%d>.org"}
            :s {:description "Todo, scheduled"
                :template "* TODO %?\n  SCHEDULED: %^{Scheduled date}t\n  %U"
                :target "~/org/journal/%<%Y-%m-%d>.org"}
            :d {:description "Todo, with deadline"
                :template "* TODO %?\n  SCHEDULED: %^{Scheduled date}t\n  DEADLINE: %^{Deadline date}t\n  %U"
                :target "~/org/journal/%<%Y-%m-%d>.org"}
            :j {:description "Journal"
                :template "* %?\n  %U"
                :target "~/org/journal/%<%Y-%m-%d>.org"}
        }
        :ui {
            :menu {
                :handler (fn [menu-data]
                    (let [items []]
                      (each [_ item (ipairs menu-data.items)]
                        (when (not item.icon)
                          (table.insert items item)))
                      (vim.ui.select items {
                        :prompt menu-data.title
                        :format_item #(.. $.key "  " $.label)
                        :kind "orgmode"
                      } #(when (and $ $.action) ($.action)))))
            }
            :input {
                :use_vim_ui true
            }
        }
    }
    :config (lambda [_ opts]
        ;; Ensure journal dir + today's file exists before capture
        (let [journal-dir (vim.fn.expand "~/org/journal")
              today-file  (.. journal-dir "/" (os.date "%Y-%m-%d") ".org")]
          (vim.fn.mkdir journal-dir "p")
          (when (= 0 (vim.fn.filereadable today-file))
            (let [title  (.. "#+TITLE: " (os.date "%Y-%m-%d") " JOURNAL")
                  author (.. "#+AUTHOR: " (vim.fn.expand "$USER") "@" (vim.fn.hostname))
                  header [title author ""]]
              (vim.fn.writefile header today-file))))
        (call-at :orgmode :setup opts)
        (vim.lsp.enable "org")
        (vim.api.nvim_create_autocmd "FileType" {
            :pattern "org"
            :callback #(do
                (set vim.wo.conceallevel 2)
                (set vim.wo.concealcursor "nc"))}))))

(table.insert PKG (mt
    ["akinsho/org-bullets.nvim"]
    :lazy true
    :ft ["org"]
    :config #(call-at :org-bullets :setup)))

PKG
