export ALL_PROXY="http://"$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")":7890"
export GPG_TTY=$(tty)
alias vim=nvim

