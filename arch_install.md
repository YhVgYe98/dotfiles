# install arch linux

use archinstall
auto configure:
    systemd-boot
    firewalld
    bluetooth
    iwd + networkmanager
    power-profiles-daemon
    pipewire

## base package
neovim
zsh
tmux
btop
git
ntfs-3g
exfat-utils
dosfstools
openssh
rsync
fzf
ripgrep

## device
alsa-utils
cups system-config-printer
mesa vulkan-intel

## font
terminus-font (for tty /etc/vconsole.conf)
ttf-firacode-nerd

## utils
go
python
uv
7zip
zip
unzip
unrar
npm
gcc
luarocks

## network
manual yay
wireless-regdb
mihomo
aria2

## password
pass pass-import
wl-clipboard


## GUI

### plasma
plasma
dolphin
konsole
ark
kdeconnect
gwenview
partitionmanager

### login manager
sddm

### input 
fcitx5-im
fcitx5-rime
rime-ice-git

### GUI software
vivaldi
wechat wqy-zenhei ttf-twemoji
wps-office-cn wps-office-mui-zh-cn ttf-wps-fonts ttf-ms-fonts wps-office-fonts
vlc

### steam
lib32-mesa lib32-vulkan-intel rtmpdump
steam

### password
qtpass
