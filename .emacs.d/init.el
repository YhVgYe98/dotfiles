;;  -*- lexical-binding: t; -*-

;;;;;;;;;;;; basic settings ;;;;;;;;;;;;;;;;;;;;;
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
(defun my/apply-fonts ()
  "Apply fonts to the selected frame."
  (when (display-graphic-p)
    (set-frame-font "FiraCode Nerd Font Mono-14" nil t)
    (set-fontset-font t 'han (font-spec :family "Noto Sans CJK SC"))))
(my/apply-fonts)                       ; non-daemon: initial frame
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (my/apply-fonts))))

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
;; Daemon-aware desktop restore: 等第一个 GUI frame 创建后再恢复桌面
(if (daemonp)
    (add-hook 'server-after-make-frame-hook
              (lambda ()
                (desktop-read my-desktop-dir)
                (desktop-save-mode 1)))
  (desktop-save-mode 1))
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
(use-package catppuccin-theme
  :init
  (setq catppuccin-flavor 'mocha)
  :config
  (load-theme 'catppuccin :no-confirm))

(use-package doom-modeline
  :init (doom-modeline-mode 1))
;;;;;;;;;;;;;;; dired ;;;;;;;;;;;;;;;;;;;;;
(setq dired-listing-switches "-alh")


;;;;;;;;;;;;;; input ;;;;;;;;;;;;;;;;;;;;;;
(use-package key-chord
  :after evil
  :config
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jj" 'evil-normal-state))

(use-package evil
  :init
  (setq evil-want-keybinding nil          ; 必须：让 evil-collection 接管键盘映射
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (evil-set-leader 'normal (kbd "SPC"))
  ;; ── leader keybindings ──
  ;; 保存与退出
  (evil-global-set-key 'normal (kbd "<leader>ww")  'save-buffer)
  (evil-global-set-key 'normal (kbd "<leader>qq") 'save-buffers-kill-emacs)
  ;; Buffer
  (evil-global-set-key 'normal (kbd "<leader>bb") 'switch-to-buffer)
  (evil-global-set-key 'normal (kbd "<leader>bB") 'ibuffer)
  (evil-global-set-key 'normal (kbd "<leader>bd") 'kill-current-buffer)
  ;; 窗口
  (evil-global-set-key 'normal (kbd "<leader>wv") 'split-window-right)
  (evil-global-set-key 'normal (kbd "<leader>ws") 'split-window-below)
  (evil-global-set-key 'normal (kbd "<leader>wd") 'delete-window)
  (evil-global-set-key 'normal (kbd "<leader>wo") 'delete-other-windows)
  ;; Dired
  (evil-global-set-key 'normal (kbd "<leader>dd") 'dired)
  (evil-global-set-key 'normal (kbd "<leader>dj") 'dired-jump)
  (evil-global-set-key 'normal (kbd "<leader>dD") 'dired-other-window)
  ;; 查找
  (evil-global-set-key 'normal (kbd "<leader>ff") 'consult-fd)
  (evil-global-set-key 'normal (kbd "<leader>fd") 'consult-flymake)
  (evil-global-set-key 'normal (kbd "<leader>fg") 'consult-ripgrep))
;; Evil-collection —— 为 magit/dired/diff-hl 等包自动配置 evil 风格快捷键
(use-package evil-collection
  :after evil
  :custom
  (evil-collection-setup-minibuffer t)
  :config
  (evil-collection-init))

;; Evil 增强 -- 注释操作符 gc
(use-package evil-commentary
  :after evil
  :config (evil-commentary-mode 1))
;; Evil 增强 -- 扩展 % 跳转配对
(use-package evil-matchit
  :config (global-evil-matchit-mode 1))

(with-eval-after-load 'dired
  (evil-define-key 'normal dired-mode-map (kbd "SPC") nil))


;;;;;;;;;;;;; editing enhancements ;;;;;;;;;;;;;;;
;; 彩虹括号 —— 嵌套括号按深度分色，肉眼分辨层级，Lisp/JSON/JS 必备
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))


;;;;;;;;;;;;; project management ;;;;;;;;;;;;;;;
;; Projectile —— 项目管理：项目内文件搜索、切换、编译、测试
(use-package projectile
  :config
  (projectile-mode 1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map))
  :custom
  (projectile-completion-system 'auto)) ; 自动适配 vertico/consult


;;;;;;;;;;;;; minibuffer completion ;;;;;;;;;;;;;;;
;; 架构：Vertico（竖排面板）→ Marginalia（候选注释）→ Orderless（灵活匹配）→ Consult（增强命令）

;; 竖排补全面板 —— 让 minibuffer 候选列表纵向展示，支持多行、预览
(use-package vertico
  :init (vertico-mode 1))

;; 富注释 —— 为补全候选添加文件大小/模式/函数签名等旁注信息
(use-package marginalia
  :after vertico
  :init (marginalia-mode 1))

;; 无序匹配 —— 输入多个关键词（空格分隔），任意顺序都能命中
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; 咨询增强 —— 为 switch-buffer/goto-line/imenu/xref 等内置命令提供预览、分组、异步搜索
;; consult-ripgrep 是项目级全文搜索的入口
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



;; 动作菜单 —— 对任意补全候选按 C-. 弹出操作菜单（删除/重命名/打开外部等）
;; embark-consult 为 consult 的候选提供了专属动作（如对搜索结果批量编辑）
(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult)

;;;;;;;;;;;;; in-buffer completion ;;;;;;;;;;;;;;;;;;
;; 架构：Corfu（buffer 内弹出面板）→ Cape（补全后端）→ Corfu-terminal（终端兼容）

;; buffer 内补全弹出面板 —— 在光标位置弹出候选列表，类似 VSCode 的 IntelliSense
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)                  ; 自动弹出
  (corfu-auto-delay 0.1)          ; 输入停止 0.1 秒后弹出
  (corfu-auto-prefix 2)           ; 至少输入 2 个字符才触发
  (corfu-cycle t)                 ; 首尾循环
  (corfu-quit-no-match 'separator) ; 无匹配时自动关闭
  (corfu-preselect 'prompt)       ; 预选第一项但不抢占回车
  :bind
  (:map corfu-map
        ("SPC" . corfu-insert-separator)  ; 空格=分隔符，配合 orderless 多词搜索
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous)))

;; 终端兼容 —— 在 TUI Emacs 中让 Corfu 使用子菜单位置而非悬浮 popup
(use-package corfu-terminal
  :after corfu
  :unless (display-graphic-p)
  :config (corfu-terminal-mode 1))

;; 文档弹窗 —— 选中候选时在侧边弹出文档/签名（corfu 自带扩展，无需单独安装）
(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay '(0.5 . 0.5))   ; (弹出延迟 . 隐藏延迟)
  (corfu-popupinfo-max-width 70)
  (corfu-popupinfo-max-height 20))

;; 图标装饰 —— 在 Corfu 候选列表中为不同文件类型/函数/变量添加 Nerd Icon
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; 补全后端扩展 —— 为 completion-at-point 额外注册 dabbrev（当前buffer单词）和 file（路径）后端
;; 这样 Eglot 提供 LSP 补全的同时，还能回退到 buffer 单词和文件路径补全
(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block))


;;;;;;;;;;;;;;; LSP client ;;;;;;;;;;;;;;;;;;;;

(use-package mason
  :config
  (mason-ensure))
;; Eglot —— Emacs 内置 LSP 客户端，轻量、和 Emacs 原生能力深度整合
(use-package eglot
  :hook
  ;; 同时 hook 原生 mode 和 ts-mode：安装 tree-sitter 语法后走 ts-mode，
  ;; 未安装则回退到原生 mode，eglot 都能正确启动
  ((python-mode python-ts-mode
    c-mode c-ts-mode
    c++-mode c++-ts-mode
    java-mode java-ts-mode
    js-mode js-ts-mode
    typescript-mode typescript-ts-mode
    rust-mode rust-ts-mode
    go-mode go-ts-mode
    fennel-mode fennel-ts-mode c           ; 当前无效
    web-mode) . eglot-ensure)
  :config
  (setq eglot-events-buffer-size 0)        ; 关闭事件日志 buffer，节省内存
  (setq eglot-sync-connect 0)              ; 不阻塞 UI，LSP 异步连接
  (setq eglot-autoshutdown t)              ; 关闭最后一个 buffer 时自动关闭 LSP server，节省内存
  ;; 若保存时卡顿可开启下面这行，让 eglot 降低推送频率
  ;; (setq eglot-send-changes-idle-time 0.5)
  :bind
  (:map eglot-mode-map
        ("C-c r" . eglot-rename)           ; 重命名符号
        ("C-c a" . eglot-code-actions)     ; 代码动作（自动修复/重构）
        ("C-c f" . eglot-format)))         ; 格式化

;;;;;;;;;;;;; tree-sitter ;;;;;;;;;;;;;;;;;;;;
;; treesit-auto —— 自动管理 tree-sitter grammar 和 mode 切换
;; 首次打开文件时提示安装 grammar，已安装则自动切到 ts-mode，未安装则静默回退
;; M-x treesit-auto-install-all 可一键安装全部 grammar
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)          ; 缺少 grammar 时弹提示询问
  :config
  (treesit-auto-add-to-auto-mode-alist 'all) ; 为 rust/go/toml 等无原生mode的语言注册 ts-mode
  (global-treesit-auto-mode)
  (setq treesit-font-lock-level 4))

;;;;;;;;;;;;; version control ;;;;;;;;;;;;;;;;;;
;; Magit —— Git 交互
;; C-x g 打开 magit-status，? 查看所有快捷键
(use-package magit
  :bind ("C-x g" . magit-status))

;; Diff-HL —— 行号区显示 Git 改动状态（新增/修改/删除）
;; 独立于 magit 工作（底层用 vc-mode），magit hook 是额外增强
(use-package diff-hl
  :config
  (global-diff-hl-mode)
  :hook
  ((magit-pre-refresh . diff-hl-magit-pre-refresh)
   (magit-post-refresh . diff-hl-magit-post-refresh)
   (vc-checkin . diff-hl-update)))

;;;;;;;;;;;;; debugger ;;;;;;;;;;;;;;;;;;;;
;; Dape —— Debug Adapter Protocol 客户端，类似 VSCode 的调试体验
;; 快捷键：M-x dape 启动调试，具体 language adapter 见 dape 文档
(use-package dape
  :config
  ;; 默认从项目根目录启动 debug adapter
  (add-to-list 'dape-cwd-fn 'project-root)
  :bind
  (:map dape-mode-map
        ("<f5>" . dape)            ; 启动/继续
        ("<f9>" . dape-breakpoint-toggle)  ; 断点切换
        ("<f10>" . dape-next)      ; 单步跳过
        ("<f11>" . dape-step-in))) ; 单步进入


;;;;;;;;;;;;; python ;;;;;;;;;;;;;;;;;;;;
(use-package pet
  :config
  (add-hook 'python-base-mode-hook 'pet-mode -10))


;;;;;;;;;;;;; fennel ;;;;;;;;;;;;;;;;;;;;
(use-package fennel-mode
  :mode ("\\.fnl\\'" "\\.fnlm\\'" "/fennelrc\\'")

  :hook
  ((fennel-mode . eglot-ensure)))           ; 打开 .fnl 自动启动 eglot + fennel-ls

