;;; -*- lexical-binding: t no-byte-compile: t -*-

;; 添加文件搜索路径
;; (add-to-list 'load-path "~/.emacs.d/config/")1


;;; ===================== 基础设置 =======================
;; 关闭工具栏
(tool-bar-mode -1)
;; 关闭菜单栏
(menu-bar-mode -1)
;; 关闭文件滑动控件
(scroll-bar-mode -1)
;; 显示行号
(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'relative)
;; 连续滚动
(setq scroll-conservatively 101
      scroll-margin 0
      scroll-step 0)
;; 禁止自动备份
(setq make-backup-files nil)
;; 设置临时文件夹路径
(setq temporary-file-directory
      (expand-file-name (concat user-emacs-directory "temp-files/")))
(unless (file-exists-p temporary-file-directory)
    (make-directory temporary-file-directory t))
;; 设置统一的自动保存路径
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name temporary-file-directory) t)))
;; 设置统一的锁文件路径
(setq lock-file-name-transforms
      `((".*" ,(expand-file-name temporary-file-directory) t)))
;; 文件被外部程序修改时，自动还原
(auto-revert-mode 1)
;; fido自动补全
(fido-mode 1)
(fido-vertical-mode 1)
;; 设置custom设置保存路径
(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))
;; 关闭欢迎页
(setq inhibit-splash-screen t)
;; 退出时保存当前状态
;(desktop-save-mode 1)
;; 高亮当前行 TODO:没有语法高亮
; (global-hl-line-mode 1)
;; 停止响铃
(setq visible-bell t)
;; 用y/n替换所有yes/no
(defalias 'yes-or-no-p 'y-or-n-p)


(add-hook 'prog-mode-hook 'column-number-mode) ;在ModeLine显示列号
(setq-default column-number-indicator-zero-based nil) ; 列号从1开始
(add-hook 'prog-mode-hook 'display-line-numbers-mode) ;显示行号
(add-hook 'prog-mode-hook 'electric-pair-mode) ;括号的配对
;(add-hook 'prog-mode-hook 'flymake-mode) ;错误的提示
;(add-hook 'prog-mode-hook 'hs-minor-mode) ;代码的折叠
;(global-set-key (kbd "M-n") #'flymake-goto-next-error) ;错误跳转快捷键 TODO 设置vim style
;(global-set-key (kbd "M-p") #'flymake-goto-prev-error)

;(when (version<= "29" emacs-version)
;  (global-tab-line-mode 1)
;  (tab-bar-mode 1))


;;; ======================== use-package 设置 =====================
;; The default only includes elpa.gnu.org, but a lot of my installed packages
;; come from MELPA.
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")
        ("org" . "https://orgmode.org/elpa/")))

;; install use-pacakge
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
;; use-package config
;; 1. use-package不用确保包已安装，需要在每个use-package声明中显式地使用:ensure t来确保包已安装
;; 2. 加载时是否输出详细信息
;; 3. 设置加载package时是否输出信息，小于阈值的不输出
(setq use-package-always-ensure nil
      use-package-verbose t
      use-package-minimum-reported-time 0.0001)
;; enable use-package
(eval-when-compile
  (require 'use-package))
(require 'use-package)

;; Load packages. It's necessary to call this early.
(package-initialize)
;; The archives that package-list-packages and package-install will use.


;;; =================== 加载主题 ====================
;(load-theme 'wombat t)
(use-package doom-themes :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)
  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  ;(doom-themes-neotree-config)
  ;; or for treemacs users
  ;(setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  ;(doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))


;;; =================== 设置字体 ======================
(setq my-font-size 13.0)
(defun font-installed-p (font-name)
  "Check if font with FONT-NAME is available."
  (find-font (font-spec :name font-name)))
(when (display-graphic-p)
  (cl-loop for font in '("FiraMono Nerd Font" "Cascadia Code" "SF Mono" "Source Code Pro"
                         "Fira Code" "Menlo" "Monaco" "Dejavu Sans Mono"
                         "Lucida Console" "Consolas" "SAS Monospace")
           when (font-installed-p font)
           return (set-face-attribute
                   'default nil
                   :font (font-spec :family font
                                    :weight 'normal
                                    :slant 'normal
                                    :size (cond ((eq system-type 'gnu/linux) my-font-size)
                                                ((eq system-type 'windows-nt) my-font-size)))))
  (cl-loop for font in '("OpenSansEmoji" "Noto Color Emoji" "Segoe UI Emoji"
                         "EmojiOne Color" "Apple Color Emoji" "Symbola" "Symbol")
           when (font-installed-p font)
           return (set-fontset-font t 'unicode
                                    (font-spec :family font
                                               :size (cond ((eq system-type 'gnu/linux) my-font-size)
                                                           ((eq system-type 'windows-nt) my-font-size)))
                                    nil 'prepend))
  (cl-loop for font in '("思源黑体 CN" "思源宋体 CN" "微软雅黑 CN"
                         "Source Han Sans CN" "Source Han Serif CN"
                         "WenQuanYi Micro Hei" "文泉驿等宽微米黑"
                         "Microsoft Yahei UI" "Microsoft Yahei")
           when (font-installed-p font)
           return (set-fontset-font t '(#x4e00 . #x9fff)
                                    (font-spec :name font
                                               :weight 'normal
                                               :slant 'normal
                                               :size (cond ((eq system-type 'gnu/linux) my-font-size)
                                                           ((eq system-type 'windows-nt) my-font-size)))))
  (cl-loop for font in '("HanaMinB" "SimSun-ExtB")
           when (font-installed-p font)
           return (set-fontset-font t '(#x20000 . #x2A6DF)
                                    (font-spec :name font
                                               :weight 'normal
                                               :slant 'normal
                                               :size (cond ((eq system-type 'gnu/linux) my-font-size)
                                                           ((eq system-type 'windows-nt) my-font-size))))))


;;; =================== evil 绑定 =================
; leader for elisp function
(use-package key-chord :ensure t
  :config
  (key-chord-mode 1))
(use-package evil :ensure t
  :after key-chord
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (evil-set-leader nil (kbd "SPC"))
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state)
  ;(evil-define-key 'normal 'global (kbd "<leader>e") 'treemacs)
  ;(evil-define-key 'treemacs treemacs-mode-map (kbd "<leader>e") 'treemacs)

)
(use-package evil-collection :ensure t
  :after evil
  :config
  (evil-collection-init))


;;; ======================= mode-line 配置 ========================
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

;(use-package moody :ensure t
;  :config
;  (moody-replace-mode-line-front-space)
;  (moody-replace-mode-line-buffer-identification)
;  (moody-replace-vc-mode))

;(use-package smart-mode-line :ensure t
;  :config
;  (sml/setup))
;(use-package mini-modeline :ensure t
;  :config
;  (mini-modeline-mode t))

;;; =================== treemacs/dired ==================
(use-package nerd-icons :ensure t)
;(use-package treemacs :ensure t)
;(use-package treemacs-nerd-icons :ensure t :after treemacs nerd-icons
;  :config (treemacs-load-theme "nerd-icons"))
;(use-package treemacs-evil :ensure t :after treemacs evil)
(use-package nerd-icons-dired :ensure t
  :hook
  (dired-mode . nerd-icons-dired-mode))


(defun create-sidebar (ratio)
  "Create a sidebar window on the left side of the frame with a width proportional to the frame's total columns, and switch to it.
   RATIO is the proportion of the frame's width to use for the sidebar."
  ;(interactive "nEnter the ratio of the frame's width for the sidebar: ")
  (let* ((frame-columns (frame-width))
         (sidebar-width (max 1 (round (* frame-columns ratio))))  ;; 确保sidebar宽度至少为1
         (sidebar-window (split-window nil sidebar-width 'right)))
    (select-window sidebar-window)))
(defun dired-open-sidebar ()
  "Split vertically, create a dired window"
  (create-sidebar .3) 
  (other-window 1)
  (dired-jump))
(defun dired-window-exists-p ()
  "Return the Dired window if it exists in the current frame, otherwise return nil."
  (catch 'found
    (walk-windows (lambda (win)
                    (when (eq (with-current-buffer (window-buffer win) major-mode) 'dired-mode)
                      (throw 'found win)))
                  nil 'visible)
    nil))
(defun dired-sidebar-toggle ()
  "toggle show state of dired sidebar"
  (interactive)
  (let ((dired-window (dired-window-exists-p)))
    (if dired-window
	(delete-window dired-window)
        (dired-open-sidebar))))
(evil-define-key 'normal 'global (kbd "<leader>e") 'dired-in-veritcal-split)

;;; ==================== other =====================
(use-package which-key :ensure t
  :config
  (which-key-mode))

(use-package company :ensure t :defer t
  :hook (after-init . global-company-mode)) ; company-mode是只在编程中启用


;;; ==================== lsp ============================
; (use-package eglot :ensure t :defer t
;   :hook (prog-mode . eglot-ensure))

;;; ====================== treesit =======================
(use-package treesit
  :when (and (fboundp 'treesit-available-p)
	     (treesit-available-p))
  :config
  (setq treesit-font-loc-level 4)  ; 默认是3，越高则高亮的语法越多
  )

;(use-package treesit-auto :ensure t
;  :after treesit
;  :config
;  (global-treesit-auto-mode)
;  (setq treesit-auto-install 'prompt))

