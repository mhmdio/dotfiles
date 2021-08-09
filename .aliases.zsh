alias zshreload='source ~/.zshrc' # reload ZSH
alias zchange='code ~/.zshrc'     #
alias gchange='code ~/.gitconfig' #
alias maws='micro ~/.aws/config'
alias shtop='sudo htop'        # run `htop` with root ri ghts
alias grep='grep --color=auto' # colorize `grep` output
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias less='less -R'

alias ll='exa'
alias cat='bat'

alias rm='rm -i' # confirm removal
alias cp='cp -i' # confirm copy
alias mv='mv -i' # confirm move

alias cal='gcal --starting-day=1' # print simple calendar f or current month
alias weather='curl v2.wttr.in'   # print weather for curre nt location (https://github.com/chubin/wttr.in)

alias tf='terraform'
alias tfi='terraform init'
alias tfv='terraform validate'
alias tff='terraform fmt'
alias tfgu='terraform get --update'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tg='terragrunt'
alias cl='clear'
alias k='kubectl'
alias mk='minikube'
alias m='micro'

alias python='python3'
alias pip='pip3'
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew  doctor'
