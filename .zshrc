
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
# Functions
# -------------------------------
# Create and navigate to a new directory
mkcd() {
    mkdir -p "${1}"
    cd "${1}"
}

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

# ASDF version manager
# . /opt/homebrew/opt/asdf/libexec/asdf.sh

# Conda initialization
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

# Direnv initialization for environment-specific configurations
# eval "$(direnv hook zsh)"

# Custom function path
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Script to take over environment for ngp
takeover () {
	target_env=$1
	service_name=$2
	target_role=$3
	echo "Please select the development role where we will build:"
	. assume "Built-Dev/BuiltDeveloper"
	export AWS_PAGER=""
	source_version=$(git rev-parse HEAD)
	build_id=$(aws codebuild start-build \
      --project-name $service_name-build \
      --source-version "$source_version" \
      --output json | jq -r '.build.id'
      )
	echo "Started build $build_id"
	wait_for_build_completion () {
		local build_id=$1
		while true
		do
			build_status=$(aws codebuild batch-get-builds --ids "$build_id" | jq -r '.builds[0].buildStatus')
			if [ "$build_status" = "SUCCEEDED" ]
			then
				echo "Build succeeded"
				break
			elif [ "$build_status" = "FAILED" ]
			then
				echo "Build failed"
				return 1
			fi
			echo "Build status: $build_status - waiting for completion..."
			sleep 10
		done
	}
	wait_for_build_completion "$build_id"
	echo "Please select the role where we will deploy:"
	. assume "$target_role"
	build_id=$(aws codebuild start-build \
      --project-name "$target_env-$service_name" \
      --source-version "$source_version" \
      --output json | jq -r '.build.id'
      )
	echo "Started build for $service_name in $target_env: $build_id"
	wait_for_build_completion "$build_id"
}
