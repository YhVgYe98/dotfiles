export ALL_PROXY="http://$(ip route show | grep -i default | awk '{print $3}'):7890"
export GPG_TTY=$(tty)
alias vim=nvim

