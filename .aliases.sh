#!/bin/bash

# Easier navigation
alias ..="cd .."                        # go up 1 level
alias ...="cd ../.."                    # go up 1 level
alias ....="cd ../../.."                # go up 1 level
alias .....="cd ../../../.."            # go up 1 level
alias ~="cd ~"                          # go up 1 level

# Terminal shortcuts
alias c="clear"
alias sc="source"

# Normal commands with extra utility
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Personal shortcuts
alias als="cat .aliases"
alias fns="ls ~/bin"

# Git commands
alias gst="git status"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias ga="git add"
alias gb="git branch"
alias gf="git fetch"
alias gbr="git branch -r"
alias gd="git diff"
alias grd="git fetch origin && git rebase origin/master"
alias gp="git push -u 2>&1 | tee >(cat) | grep \"pull/new\" | awk '{print \$2}' | xargs open"
alias git-current-branch="git branch | grep \* | cut -d ' ' -f2"

alias lg=lg1
alias lg1=lg1-specific --all
alias lg2=lg2-specific --all
alias lg3=lg3-specific --all
    alias lg1-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'"
    alias lg2-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'"
    alias lg3-specific="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'"
