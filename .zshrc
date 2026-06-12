
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
# Optimized Paths and Environment Variables
# -------------------------------
# Keep user scripts first while allowing macOS, Linux, and WSL package paths.
typeset -U path PATH
for dotfiles_path in \
  "$HOME/bin" \
  "$HOME/.local/bin" \
  "/opt/homebrew/bin" \
  "/usr/local/bin" \
  "/home/linuxbrew/.linuxbrew/bin"; do
  [[ -d "$dotfiles_path" ]] && path=("$dotfiles_path" $path)
done
unset dotfiles_path

# Language environment variable to prevent locale-related warnings
export LANG=en_US.UTF-8

# Set default editor to Neovim
export EDITOR=nvim

# Keep Navi config in a stable, dotfiles-managed location.
export NAVI_CONFIG="$HOME/.config/navi/config.yaml"

# Automatically load trusted per-project environment files, and unload them
# when leaving the project directory.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# -------------------------------
# Zsh Aliases (Fast Loading)
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
# Set theme to Powerlevel10k when it is installed.
if [ -f ~/powerlevel10k/powerlevel10k.zsh-theme ]; then
  source ~/powerlevel10k/powerlevel10k.zsh-theme
fi

# Load Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# -------------------------------
# History Configuration
# -------------------------------
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

# Keep machine-local exports and secrets out of git.
[ -f "$HOME/.dotfiles/.local.zsh" ] && source "$HOME/.dotfiles/.local.zsh"
