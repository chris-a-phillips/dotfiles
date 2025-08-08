
# -------------------------------
# Powerlevel10k Initialization
# -------------------------------
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -------------------------------
# Paths and Environment Variables
# -------------------------------
# Standard path setup with custom directories
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/.dotfiles/scripts:$PATH"
export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
export LOCAL="$HOME/.local"
export PATH="$LOCAL/bin:$PATH"

# Set repository path for easy access
export SOURCE_REPO_PATH="/Users/chris.phillips/environment/dim/draw/integration-pipelines"

# Language environment variable to prevent locale-related warnings
export LANG=en_US.UTF-8

# Set default editor to Neovim
export EDITOR=nvim

# -------------------------------
# Zsh Aliases
# -------------------------------
# Load custom aliases from .dotfiles
if [ -f ~/.dotfiles/.aliases ]; then
    . ~/.dotfiles/.aliases
fi

# -------------------------------
# Custom Key Bindings
# -------------------------------
# Fix ctrl+r in tmux for incremental search
bindkey '^R' history-incremental-search-backward
# Bind ctrl+p for navigating up history
bindkey '^P' up-history


# -------------------------------
# Theme and Prompt Customization
# -------------------------------
# Set theme to Powerlevel10k and load theme
source ~/powerlevel10k/powerlevel10k.zsh-theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -------------------------------
# Plugin Initializations
# -------------------------------
# NVM (Node Version Manager) setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Pyenv setup for managing Python versions
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# Direnv initialization for environment-specific configurations
# eval "$(direnv hook zsh)"

# History file setup
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Only skip saving identical commands run back-to-back
setopt HIST_IGNORE_DUPS

# Helpful additional settings (but not full deduping)
setopt INC_APPEND_HISTORY      # Immediately write to file
setopt SHARE_HISTORY           # Share across sessions
setopt HIST_REDUCE_BLANKS      # Trim extra spaces
