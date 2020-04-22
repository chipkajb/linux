

############################################################################################
######################## CUSTOM CONFIGURATION ADDED BY JORDAN CHIPKA #######################
############################################################################################


# Aliases
alias python=python3
alias home='cd ~'
alias root='cd /'
alias ..='cd ..'
alias ...='cd ..; cd ..'
alias ....='cd ..; cd ..; cd ..'
alias o=xdg-open
alias vimrc='vim ~/.vimrc'
alias bashrc='vim ~/.bashrc'
alias grep='grep --color=always'

# more customizations
export EDITOR=vim
export HISTTIMEFORMAT="%h %d %H:%M:%S " # show date and time in history
export HISTSIZE=10000 # increase history size
export HISTFILESIZE=10000

# git configurations
git config --global user.name "chipkajb"
git config --global user.email "jbc274@cornell.edu"
git config --global push.default simple
