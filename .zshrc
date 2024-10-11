# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$PATH:/usr/local/bin
export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"


# zsh aliases
if [ -f ~/.dotfiles/.aliases ]; then
    . ~/.dotfiles/.aliases
fi
source ~/powerlevel10k/powerlevel10k.zsh-theme

ZSH_THEME="powerlevel10k/powerlevel10k"




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

# Fix to ctrl+r in tmux
bindkey '^R' history-incremental-search-backward
# Added ctrl+p for good measure, since that was also broken
bindkey '^P' up-history

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export EDITOR=nvim


export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
