;;; early-init.el —— Emacs 启动性能优化

;; ── GC 阈值：启动时放大，启动后收缩 ──
(setq gc-cons-threshold (* 1024 1024 128)  ; 128MB 启动期间
      gc-cons-percentage 1.0)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 1024 1024 2)  ; 2MB 启动后
                  gc-cons-percentage 0.2)))

;; ── IPC 缓冲区：加大读取块，减少进程通信开销 ──
(setq read-process-output-max (* 1024 1024))  ; 1MB

;; ── 延迟文件操作 hook：启动完成后再加载 ──
(defvar last-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist last-file-name-handler-alist)))

;; ── 不在 early-init 阶段加载任何包，交给 init.el 手动 package-initialize ──
(setq package-enable-at-startup nil)

;; ── 静默 native-comp 警告 ──
(setq native-comp-async-report-warnings-errors 'silent)

;; ── 禁用站点 elisp（系统级别的 site-start.el 会引入不可控的启动开销）──
(setq site-run-file nil)

(provide 'early-init)
