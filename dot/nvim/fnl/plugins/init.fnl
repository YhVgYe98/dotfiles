(local {
    : set-opts
    : mt
    : req-at
    : call-at}
(require :utils))

(local lazypath
       (.. (vim.fn.stdpath "data") "/lazy/lazy.nvim"))

(if (let [stat_pkg (or vim.uv vim.loop)]
      (not (stat_pkg.fs_stat lazypath)))
    (do
        (local lazyrepo "https://github.com/folke/lazy.nvim.git")
        (local out
               (vim.fn.system ["git" "clone" "--filter=blob:none" "--branch=stable" lazyrepo lazypath]))
        (if (~= vim.v.shell_error 0)
            (do
                (vim.api.nvim_echo
                  [["Failed to clone lazy.nvim:\n" "ErrorMsg"]
                   [out "WarningMsg"]
                   ["\nPress any key to exit..."]]
                  true {})
                (vim.fn.getchar)
                (os.exit 1)))))

(vim.opt.rtp:prepend lazypath)


;;;;;;;;;;;;; PLUGINS ;;;;;;;;;;;;;
(local PKG {})
(table.insert PKG (require :plugins.ui))
(table.insert PKG (require :plugins.core))
(table.insert PKG (require :plugins.extras))

;;;;;;;;;;;;; FILETYPE PLUGINS ;;;;;;;;;;;;;
(each [name type (vim.fs.dir (.. (vim.fn.stdpath :config) :/fnl/plugins/ft))]
     (when (and (= type "file") (name:match "%.fnl$"))
       (let [mod (name:gsub "%.fnl$" "")]
         (table.insert PKG (require (.. :plugins.ft. mod))))))

;;;;;;;;;; install all packages ;;;;;;;;;;;
(call-at :lazy :setup
  {:spec    PKG
   :install {:colorscheme ["habamax"]}
   :checker {:enable true}})
