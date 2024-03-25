
export PATH=$HOME/bin:/usr/local/bin:$PATH
export SOURCE_REPO_PATH="/Users/chris.phillips/environment/dim/draw/integration-pipelines"
# export PATH=$PATH:/usr/local/bin
# export PATH=/opt/homebrew/bin:$PATH
export LOCAL="$HOME/.local"
export PATH="$LOCAL/bin:$PATH"

# bash aliases
if [ -f ~/.dotfiles/.aliases ]; then
    . ~/.dotfiles/.aliases
fi

# alias python=python3
# alias pip=pip3

mkcd() {
    mkdir -p "${1}"
    cd "${1}"
}

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# eval "$(pyenv init -)"

. /opt/homebrew/opt/asdf/libexec/asdf.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/chris.phillips/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/chris.phillips/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/chris.phillips/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/chris.phillips/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

eval "$(direnv hook zsh)"
fpath+=${ZDOTDIR:-~}/.zsh_functions
