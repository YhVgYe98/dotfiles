# install arch linux

> 目的：换机后快速安装必要程序、通用软件和实用组件。

## archinstall configure:

+ btrfs
+ disable swap on zram
+ grub2 (os-prober efibootmgr)
+ linux-zen + linux-zen-headers (备用内核 linux linux-lts，各带 headers)
+ linux-firmware amd-ucode
+ plasma-meta
+ bluetooth (bluez-utils)
+ pipewire
+ printer service (cups system-config-printer)
+ power-profiles-daemon (笔记本会装 tlp tlp-pd，见可选区)
+ firewalld
+ networkmanager+iwd

## base package:

+ neovim
+ zsh
+ tmux
+ git git-lfs man-db
+ btop gdu fastfetch
+ ntfs-3g exfatprogs
+ openssh rsync
+ fd fzf ripgrep
+ base-devel
+ less reflector
+ 7zip zip unzip unrar
+ aria2 wget
+ tree bc tldr
+ nmap nethogs ddrescue
+ smartmontools usbutils dmidecode powertop

## device:

+ mesa vulkan-radeon (AMD 核显)
+ nvidia-open-dkms nvidia-utils nvidia-settings (RTX 独显，dkms)
+ alsa-utils

## language

locale-gen
user level LANG

必装（依赖原因）：fennel + Rust + Go + Python
+ go
+ python uv npm luarocks
+ rustup

其余语言与构建工具见可选区

## font (必装):

+ terminus-font (for tty /etc/vconsole.conf)
+ ttf-firacode-nerd
+ noto-fonts-cjk wqy-zenhei

## network:

+ manual install yay
+ mihomo-bin (AUR)

## password:

+ pass
+ wl-clipboard
+ qtpass (GUI)

## github:

+ github-cli

## GUI

### plasma

+ plasma-meta
+ dolphin konsole ark gwenview okular partitionmanager kdeconnect
+ kalk (KDE 项目)

### login manager

use default plasma-login-manager (plasmalogin.service)

### input

+ fcitx5-im
+ fcitx5-rime
+ rime-ice-git (AUR)

### GUI software

+ helium-browser-bin (AUR)
+ vlc

## 可选 (可能会装，分类罗列)

### secure boot

+ sbctl sbsigntools (自有密钥流程见 SecureBoot迁移记录；NVIDIA DKMS 自动签 = framework.conf.d/50-signing.conf)

### virtualization (KVM)

+ libvirt qemu-desktop virt-manager virt-viewer
+ dnsmasq swtpm edk2-ovmf virtiofsd
+ remmina (KVM 项目，RDP 连接虚机)

### containers

+ docker docker-compose
+ podman podman-compose

### sync

+ syncthing (systemctl --user 管理)

### 笔记本电源

+ tlp tlp-pd (笔记本会装)

### 系统工具

+ dosfstools man-pages-zh_cn pass-import wireless-regdb
+ downgrade (AUR)

### 办公 / 通讯

+ wps-office-cn wps-office-mui-zh-cn ttf-wps-fonts ttf-ms-fonts wps-office-fonts
+ wechat ttf-twemoji

### 游戏 / 图形

+ steam lib32-mesa lib32-vulkan-radeon lib32-nvidia-utils
+ krita

### 服务器 / 媒体

+ jellyfin-server jellyfin-web
+ moonlight-qt llama-swap-bin (AUR)
+ flatpak: com.baidu.NetDisk (百度网盘)

### 开发扩展

+ cmake meson gdb clang lldb
+ jdk17-openjdk clojure leiningen ghc sbcl racket-minimal python-pipx
+ boost openblas sdl2_image sdl2_mixer sdl2_ttf tree-sitter-cli
+ ffmpeg sox
+ beancount beangulp beanquery fava (记账栈，AUR)
