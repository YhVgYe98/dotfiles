;; -*- no-byte-compile: t; lexical-binding: t; -*-

;;;;;;;;;;;; basic settings ;;;;;;;;;;;;;;;;;;;;;;;
(setq inhibit-startup-screen 1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 0))
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode 0))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 0))

(setq-default display-line-numbers-type 'visual)
(global-display-line-numbers-mode 1)
(global-hl-line-mode 1)

(setq scroll-margin 5
      scroll-conservatively 10000)

(unless (display-graphic-p)
  (xterm-mouse-mode 1))

(global-auto-revert-mode t)
(show-paren-mode 1)
(which-key-mode 1)
(recentf-mode 1)

;;;;;;;;;;;;;; whitespace mode ;;;;;;;;;;;;;;;;;;;;
(setq whitespace-display-mappings
      '((space-mark 32 [183] [46])
        (tab-mark 9 [187 9] [92 9])))
(setq whitespace-style
      '(face
        trailing
        tab-mark))
(global-whitespace-mode 1)



;;;;;;;;;;;;;;;; font ;;;;;;;;;;;;;;;;;;;;;;;
(if (display-graphic-p)
    (progn
      (set-face-attribute 'default nil
			  :font (font-spec :family "FiraMono Nerd Font" :size 33))
      (set-fontset-font t 'han (font-spec :family "等线"))))


;;;;;;;;;;;;;; custom ;;;;;;;;;;;;;;;;;;;;;
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))


;;;;;;;;;;;;; package ;;;;;;;;;;;;;;;;;;;
(require 'package)
(setq package-archives '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("nongnu". "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
                         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)


;;;;;;;;;;;;;;;;; auto open ;;;;;;;;;;;;;;;
(save-place-mode 1)
(defvar my-desktop-dir (expand-file-name "desktop-sessions/" user-emacs-directory))
(unless (file-exists-p my-desktop-dir)
  (make-directory my-desktop-dir))
(desktop-save-mode 1)
(setq desktop-path (list my-desktop-dir))
(setq desktop-dirname my-desktop-dir)
(setq desktop-save t)
(setq desktop-load-locked-desktop t)
;;; Backup Settings
(defvar my-backup-dir (expand-file-name "backup/" user-emacs-directory))
(unless (file-exists-p my-backup-dir)
  (make-directory my-backup-dir t))
(setq make-backup-files t                ; 开启备份
      backup-by-copying t                ; 复制文件而不是重命名（保护软链接）
      version-control t                  ; 使用版本号备份
      delete-old-versions t              ; 删除旧备份时不询问
      kept-old-versions 2                ; 保留最早的n个备份
      kept-new-versions 2                ; 保留最新的n个备份
      backup-directory-alist `(("." . ,my-backup-dir))) ; 所有备份放这里
;;; Auto-save Settings
(defvar my-autosave-dir (expand-file-name "autosave/" user-emacs-directory))
(unless (file-exists-p my-autosave-dir)
  (make-directory my-autosave-dir t))
(setq auto-save-default t
      auto-save-timeout 20               ; 闲置n秒后自动保存
      auto-save-interval 1000            ; 输入n个字符后自动保存
      auto-save-file-name-transforms `((".*" ,my-autosave-dir t)))


;;;;;;;;;;;;;;; theme ;;;;;;;;;;;;;;;;;;;;;
;(use-package atom-one-dark-theme
;  :config
;  (load-theme 'atom-one-dark t))
(use-package modus-themes
  :config
  (load-theme 'modus-vivendi t))


;;;;;;;;;;;;;; input ;;;;;;;;;;;;;;;;;;;;;;
(use-package key-chord
  :after evil
  :config
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state))


(use-package evil
  :init
  (setq evil-want-C-u-scroll t
	evil-undo-system 'undo-redo)
  :config (evil-mode 1))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(use-package vertico
  :init (vertico-mode 1))


(use-package marginalia
  :after vertico
  :init (marginalia-mode 1))


(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))


(use-package consult
  :bind (([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ([remap yank-pop] . consult-yank-pop)
         ([remap goto-line] . consult-goto-line)
         ([remap imenu] . consult-imenu)
         ([remap project-find-regexp] . consult-ripgrep))
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref))


(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                 ; 自动开启补全
  (corfu-auto-delay 0.1)         ; 自动补全延迟
  (corfu-auto-prefix 2)          ; 输入2个字符后开始补全
  (corfu-cycle t)                ; 允许循环选择
  (corfu-quit-no-match 'separator) ; 如果没有匹配项，自动退出
  (corfu-preselect 'prompt)      ; 默认选中第一项，但允许直接回车输入当前内容
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator) ; 空格作为分隔符（配合orderless）
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous)))
(use-package corfu-terminal
  :after corfu
  :unless (display-graphic-p)
  :config (corfu-terminal-mode 1))
;; Corfu 扩展功能：文档弹窗
(use-package corfu-popupinfo
  :ensure nil ; corfu 自带
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay '(0.5 . 0.5)) ; 弹出延迟和隐藏延迟
  (corfu-popupinfo-max-width 70)
  (corfu-popupinfo-max-height 20))
;; 为 Corfu 添加图标 (需要安装 nerd-icons)
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
;; 整合 Cape (Completion At Point Extensions)
;; 允许在 Eglot 开启时，依然可以使用 dabbrev (当前buffer单词) 或 file (文件路径) 补全
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block))


(use-package eglot
  :ensure t
  :hook
  ((python-mode
    c-mode
    c++-mode
    java-mode
    js-mode
    typescript-mode
    rust-mode
    go-mode
    web-mode) . eglot-ensure)
  :config
  ;; 性能优化：减少事件缓冲
  (setq eglot-events-buffer-size 0)
  ;; 禁用 flymake 每次修改都检查（可选，如果觉得卡顿可以开启）
  ;; (setq eglot-send-changes-idle-time 0.5)
  :bind
  (:map eglot-mode-map
        ("C-c r" . eglot-rename)
        ("C-c a" . eglot-code-actions)
        ("C-c f" . eglot-format)))

