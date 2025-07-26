#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
CONFIG_FILE=""
SETUP_TYPE=""

# Error handling function
handle_error() {
  local exit_code=$?
  print_error "Script failed at line $1 with exit code $exit_code"
  print_warning "Some steps may have completed successfully. You can run the script again to continue."
  exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Spinner for visual feedback
spinner() {
  local pid=$1
  local msg=$2
  local delay=0.1
  local spinstr='|/-\\'
  echo -n " $msg"
  while ps -p "$pid" &>/dev/null; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  echo " ✅"
}

run_with_spinner() {
  "$@" & spinner $! "$1"
}

# Print colored output
print_status() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
  echo -e "\n${PURPLE}=== $1 ===${NC}"
}

# Load configuration from JSON
load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    print_warning "Falling back to work configuration..."
    CONFIG_FILE="$CONFIGS_DIR/work.json"
    if [[ ! -f "$CONFIG_FILE" ]]; then
      print_error "Work configuration not found either. Please check your configs directory."
      return 1
    fi
  fi
  
  # Use jq to parse JSON (install if not available)
  if ! command -v jq &>/dev/null; then
    print_warning "jq not found, installing..."
    brew install jq
  fi
  
  CONFIG_NAME=$(jq -r '.name' "$CONFIG_FILE")
  CONFIG_DESCRIPTION=$(jq -r '.description' "$CONFIG_FILE")
  BREWFILE=$(jq -r '.brewfile' "$CONFIG_FILE")
  
  print_header "Configuration Loaded"
  print_info "Name: $CONFIG_NAME"
  print_info "Description: $CONFIG_DESCRIPTION"
  print_info "Brewfile: $BREWFILE"
}

# Choose setup type
choose_setup_type() {
  print_header "Setup Type Selection"
  print_info "Automatically selecting Work setup for new laptop"
  
  SETUP_TYPE="work"
  CONFIG_FILE="$CONFIGS_DIR/work.json"
  
  load_config
}

# OS Detection and Package Install
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
}

install_brew_packages() {
  print_info "Installing packages from $BREWFILE..."
  local BREWFILE_PATH="$SCRIPT_DIR/$BREWFILE"
  if [[ -f "$BREWFILE_PATH" ]]; then
    print_info "Running brew bundle..."
    brew bundle --file="$BREWFILE_PATH" || {
      print_warning "Some packages failed to install. Continuing with setup..."
    }
  else
    print_error "Brewfile not found: $BREWFILE_PATH"
    print_warning "Skipping package installation. You can install packages manually later."
  fi
}

install_linux_packages() {
  if command -v apt &>/dev/null; then
    sudo apt update
    xargs -a "$SCRIPT_DIR/packages.txt" sudo apt install -y
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm $(cat "$SCRIPT_DIR/packages.txt")
  fi
}

detect_os() {
  OS="$(uname)"
  print_header "OS Detection"
  case $OS in
    Darwin)
      print_info "macOS detected."
      install_homebrew
      install_brew_packages
      ;;
    Linux)
      print_info "Linux detected."
      install_linux_packages
      ;;
    *)
      print_error "Unsupported OS: $OS"
      print_warning "This script is designed for macOS and Linux. Some features may not work."
      ;;
  esac
}

# Fonts
install_nerd_fonts() {
  print_header "Installing Nerd Fonts"
  FONT_DIR="$HOME/Library/Fonts"
  [[ "$(uname)" == "Linux" ]] && FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  
  if [[ -f "$SCRIPT_DIR/fonts.txt" ]]; then
    print_info "Installing fonts from fonts.txt..."
    while IFS= read -r font_url; do
      if [[ -n "$font_url" && ! "$font_url" =~ ^[[:space:]]*# ]]; then
        font_name=$(basename "$font_url" .zip)
        print_info "Installing $font_name..."
        curl -fLo "$font_name.zip" "$font_url"
        unzip -o "$font_name.zip" -d "$FONT_DIR" 2>/dev/null || true
        rm "$font_name.zip" 2>/dev/null || true
      fi
    done < "$SCRIPT_DIR/fonts.txt"
    print_status "Fonts installed successfully."
  else
    print_warning "fonts.txt not found, skipping font installation."
  fi
}

# GUI Apps + Configs
install_manual_apps() {
  print_header "Installing Manual Apps"
  
  # Install additional casks based on configuration
  local additional_casks=$(jq -r '.packages.additional_casks[]?' "$CONFIG_FILE" 2>/dev/null || echo "")
  if [[ -n "$additional_casks" ]]; then
    print_info "Installing additional casks..."
    echo "$additional_casks" | xargs -I {} brew install --cask {}
  fi
  
  # Restore app configurations
  restore_app_configs
}

restore_app_configs() {
  print_info "App configuration files available for reference:"
  
  # Raycast
  RAYCAST_BACKUP="$SCRIPT_DIR/app_configs/raycast"
  if [[ -d "$RAYCAST_BACKUP" ]]; then
    print_info "Raycast config available: $RAYCAST_BACKUP"
  else
    print_warning "Raycast config not found."
  fi
  
  # Rectangle Pro
  RECTANGLE_CONFIG="$SCRIPT_DIR/app_configs/rectangle_pro/RectangleProConfig.json"
  if [[ -f "$RECTANGLE_CONFIG" ]]; then
    print_info "Rectangle Pro config available: $RECTANGLE_CONFIG"
  else
    print_warning "Rectangle Pro config not found."
  fi
  
  print_info "These files are for reference only - manual setup required."
}

# Git Config
setup_git_config() {
  local enable_git=$(jq -r '.git_config.enable' "$CONFIG_FILE")
  if [[ "$enable_git" == "true" ]]; then
    print_header "Git Configuration"
    
    print_info "Git configuration will be set up manually after installation"
    print_info "Run these commands to configure Git:"
    print_info "  git config --global user.name 'Your Name'"
    print_info "  git config --global user.email 'your-email@company.com'"
    
    [ -f "$HOME/.gitignore_global" ] && \
      git config --global core.excludesfile "$HOME/.gitignore_global"
    [[ "$(uname)" == "Darwin" ]] && \
      git config --global credential.helper osxkeychain
    print_status "Git configuration ready for manual setup."
  fi
}

# SSH Setup
setup_ssh() {
  local enable_ssh=$(jq -r '.ssh_setup.enable' "$CONFIG_FILE")
  if [[ "$enable_ssh" == "true" ]]; then
    print_header "SSH Key Setup"
    
    local key_type=$(jq -r '.ssh_setup.key_type' "$CONFIG_FILE")
    local key_name=$(jq -r '.ssh_setup.key_name // "id"' "$CONFIG_FILE")
    
    if [ ! -f "$HOME/.ssh/${key_name}_$key_type" ]; then
      ssh-keygen -t "$key_type" -C "$(git config --global user.email)" -f "$HOME/.ssh/${key_name}_$key_type" -N ""
    fi
    eval "$(ssh-agent -s)"
    ssh-add --apple-use-keychain ~/.ssh/${key_name}_$key_type
    print_status "SSH key generated."
    echo "🔑 Public key:"
    cat ~/.ssh/${key_name}_$key_type.pub
    print_info "Copy this to GitHub: https://github.com/settings/ssh/new"
  fi
}

# Dotfiles Setup
setup_dotfiles() {
  print_header "Dotfiles Setup"
  
  # Create missing dotfiles if they don't exist
  create_missing_dotfile() {
    local source_file="$1"
    local target_file="$2"
    local content="$3"
    
    if [[ ! -f "$source_file" ]]; then
      print_info "Creating missing dotfile: $(basename "$source_file")"
      echo "$content" > "$source_file"
    fi
  }
  
  # Create basic .zshrc if missing
  create_missing_dotfile "$SCRIPT_DIR/.zshrc" ~/.zshrc '#!/bin/zsh
# Basic zsh configuration
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export EDITOR=nvim

# Load aliases if they exist
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_REDUCE_BLANKS'

  # Create basic .gitconfig if missing
  create_missing_dotfile "$SCRIPT_DIR/.gitconfig" ~/.gitconfig '[init]
	defaultBranch = main

[core]
	editor = nvim
	pager = delta

[user]
	# Will be configured during setup

[delta]
	features = line-numbers decorations
	syntax-theme = Dracula

[merge]
	conflictstyle = diff3

[diff]
	colorMoved = default

[pager]
	log = delta
	show = delta
	diff = delta'

  # Create basic .aliases if missing
  create_missing_dotfile "$SCRIPT_DIR/.aliases" ~/.aliases '# Basic aliases
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git aliases
alias gst="git status"
alias ga="git add"
alias gc="git commit"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gp="git push"
alias gl="git pull"

# Development aliases
alias python="python3"
alias pip="pip3"'

  # Create basic .p10k.zsh if missing
  create_missing_dotfile "$SCRIPT_DIR/.p10k.zsh" ~/.p10k.zsh '# Powerlevel10k configuration
# This is a basic configuration - run p10k configure for full setup
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs)'

  # Backup existing dotfiles if they exist and aren't already symlinks
  backup_dotfile() {
    local file="$1"
    if [[ -f "$file" && ! -L "$file" ]]; then
      print_info "Backing up existing $file to ${file}.backup"
      mv "$file" "${file}.backup"
    fi
  }
  
  # Create symlinks for core dotfiles
  backup_dotfile ~/.zshrc
  backup_dotfile ~/.gitconfig
  backup_dotfile ~/.aliases
  backup_dotfile ~/.p10k.zsh
  backup_dotfile ~/.tmux.conf
  
  ln -sf "$SCRIPT_DIR/.zshrc" ~/.zshrc
  ln -sf "$SCRIPT_DIR/.gitconfig" ~/.gitconfig
  ln -sf "$SCRIPT_DIR/.aliases" ~/.aliases
  ln -sf "$SCRIPT_DIR/.p10k.zsh" ~/.p10k.zsh
  
  # Create config directories and symlinks
  mkdir -p ~/.config
  mkdir -p ~/.config/alacritty
  mkdir -p ~/.config/tmux
  
  # Handle alacritty config (TOML format)
  if [[ -f "$SCRIPT_DIR/alacritty/alacritty.toml" ]]; then
    ln -sf "$SCRIPT_DIR/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml
  fi
  
  # Handle tmux config and related files
  ln -sf "$SCRIPT_DIR/tmux/tmux.conf" ~/.tmux.conf
  ln -sf "$SCRIPT_DIR/tmux/statusline.conf" ~/.config/tmux/statusline.conf
  ln -sf "$SCRIPT_DIR/tmux/utility.conf" ~/.config/tmux/utility.conf
  ln -sf "$SCRIPT_DIR/tmux/macos.conf" ~/.config/tmux/macos.conf
  
  # Add custom scripts to PATH
  mkdir -p ~/bin
  if [ -d "$SCRIPT_DIR/scripts" ]; then
    # Remove existing scripts to avoid conflicts
    rm -rf ~/bin/* 2>/dev/null || true
    cp -r "$SCRIPT_DIR/scripts"/* ~/bin/
    chmod +x ~/bin/*
    print_status "Scripts copied to ~/bin and made executable"
  else
    print_warning "No scripts directory found"
  fi
  
  print_status "Dotfiles symlinks created."
}

install_additional_tools() {
  print_header "Additional Tools"
  
  local config=$(jq -r '.additional_tools' "$CONFIG_FILE")
  
  # Install Neovim and LazyVim
  if [[ $(echo "$config" | jq -r '.neovim_lazyvim') == "true" ]]; then
    if command -v nvim &>/dev/null; then
      print_info "Installing LazyVim..."
      if [ ! -d ~/.config/nvim ]; then
        git clone https://github.com/LazyVim/starter ~/.config/nvim
        rm -rf ~/.config/nvim/.git 2>/dev/null || true
        print_status "LazyVim installed."
      else
        print_warning "Neovim config already exists"
      fi
    else
      print_warning "Neovim not found, install with: brew install neovim"
    fi
  fi
  
  # Install Powerlevel10k theme
  if [[ $(echo "$config" | jq -r '.powerlevel10k') == "true" ]]; then
    if [ ! -d ~/powerlevel10k ]; then
      print_info "Installing Powerlevel10k theme..."
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
      print_status "Powerlevel10k installed."
    else
      print_warning "Powerlevel10k already installed"
    fi
  fi
  
  # Install Tmux Plugin Manager (TPM)
  if [[ $(echo "$config" | jq -r '.tmux_plugins') == "true" ]]; then
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      print_info "Installing Tmux Plugin Manager..."
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
      print_status "TPM installed."
    else
      print_warning "TPM already installed"
    fi
  fi
  
  # Install LazyGit
  if [[ $(echo "$config" | jq -r '.lazygit') == "true" ]]; then
    if ! command -v lazygit &>/dev/null; then
      print_info "Installing LazyGit..."
      brew install lazygit
      print_status "LazyGit installed."
    else
      print_warning "LazyGit already installed"
    fi
  fi
}

# install_languages function removed - languages are now installed via Brewfile

set_macos_defaults() {
  local enable_defaults=$(jq -r '.macos_defaults.enable' "$CONFIG_FILE")
  if [[ "$enable_defaults" == "true" ]]; then
    print_header "macOS System Preferences"
    
    # Load macOS defaults from separate file
    local macos_defaults_file=$(jq -r '.macos_defaults_file // "configs/macos_defaults.json"' "$CONFIG_FILE")
    local macos_defaults_path="$SCRIPT_DIR/$macos_defaults_file"
    
    if [[ ! -f "$macos_defaults_path" ]]; then
      print_warning "macOS defaults file not found: $macos_defaults_path"
      return
    fi
    
    print_info "Loading macOS defaults from: $macos_defaults_file"
    
    # Load settings from the separate file
    local dark_mode=$(jq -r '.settings.system.dark_mode' "$macos_defaults_path" 2>/dev/null)
    local military_time=$(jq -r '.settings.system.military_time' "$macos_defaults_path" 2>/dev/null)
    local show_hidden_files=$(jq -r '.settings.system.show_hidden_files' "$macos_defaults_path" 2>/dev/null)
    local disable_autocorrect=$(jq -r '.settings.system.disable_autocorrect' "$macos_defaults_path" 2>/dev/null)
    local disable_autocapitalize=$(jq -r '.settings.system.disable_autocapitalize' "$macos_defaults_path" 2>/dev/null)
    local show_path_bar=$(jq -r '.settings.finder.show_path_bar' "$macos_defaults_path" 2>/dev/null)
    local show_status_bar=$(jq -r '.settings.finder.show_status_bar' "$macos_defaults_path" 2>/dev/null)
    local expand_save_dialog=$(jq -r '.settings.finder.expand_save_dialog' "$macos_defaults_path" 2>/dev/null)
    local expand_print_dialog=$(jq -r '.settings.finder.expand_print_dialog' "$macos_defaults_path" 2>/dev/null)
    
    # Apply dark mode
    if [[ "$dark_mode" == "true" ]]; then
      defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    fi
    
    # Apply 24-hour time
    if [[ "$military_time" == "true" ]]; then
      defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "1" "HH:mm"
    fi
    
    # Show hidden files
    if [[ "$show_hidden_files" == "true" ]]; then
      defaults write com.apple.finder AppleShowAllFiles -bool true
    fi
    
    # Disable autocorrect
    if [[ "$disable_autocorrect" == "true" ]]; then
      defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
    fi
    
    # Disable autocapitalize
    if [[ "$disable_autocapitalize" == "true" ]]; then
      defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    fi
    
    # Show path bar in Finder
    if [[ "$show_path_bar" == "true" ]]; then
      defaults write com.apple.finder ShowPathbar -bool true
    fi
    
    # Show status bar in Finder
    if [[ "$show_status_bar" == "true" ]]; then
      defaults write com.apple.finder ShowStatusBar -bool true
    fi
    
    # Expand save dialog
    if [[ "$expand_save_dialog" == "true" ]]; then
      defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    fi
    
    # Expand print dialog
    if [[ "$expand_print_dialog" == "true" ]]; then
      defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    fi
    
    # Essential keyboard and window settings
    local faster_key_repeat=$(jq -r '.settings.system.faster_key_repeat' "$macos_defaults_path" 2>/dev/null)
    local show_all_extensions=$(jq -r '.settings.system.show_all_extensions' "$macos_defaults_path" 2>/dev/null)
    
    if [[ "$faster_key_repeat" == "true" ]]; then
      defaults write NSGlobalDomain KeyRepeat -int 30
      defaults write NSGlobalDomain InitialKeyRepeat -int 30
    else
      defaults write NSGlobalDomain KeyRepeat -int 1
      defaults write NSGlobalDomain InitialKeyRepeat -int 15
    fi
    
    if [[ "$show_all_extensions" == "true" ]]; then
      defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    fi
    
    # Dock settings
    local dock_autohide=$(jq -r '.settings.dock.autohide' "$macos_defaults_path" 2>/dev/null)
    local dock_magnification=$(jq -r '.settings.dock.magnification' "$macos_defaults_path" 2>/dev/null)
    local dock_tilesize=$(jq -r '.settings.dock.tilesize' "$macos_defaults_path" 2>/dev/null)
    local dock_mru_spaces=$(jq -r '.settings.dock.mru_spaces' "$macos_defaults_path" 2>/dev/null)
    
    if [[ "$dock_autohide" == "true" ]]; then
      defaults write com.apple.dock autohide -bool true
    else
      defaults write com.apple.dock autohide -bool false
    fi
    
    if [[ "$dock_magnification" == "true" ]]; then
      defaults write com.apple.dock magnification -bool true
    else
      defaults write com.apple.dock magnification -bool false
    fi
    
    if [[ -n "$dock_tilesize" && "$dock_tilesize" != "null" ]]; then
      defaults write com.apple.dock tilesize -int "$dock_tilesize"
    fi
    
    if [[ "$dock_mru_spaces" == "true" ]]; then
      defaults write com.apple.dock mru-spaces -bool true
    else
      defaults write com.apple.dock mru-spaces -bool false
    fi
    
    # Finder settings
    local finder_view_style=$(jq -r '.settings.finder.view_style' "$macos_defaults_path" 2>/dev/null)
    local finder_show_sidebar=$(jq -r '.settings.finder.show_sidebar' "$macos_defaults_path" 2>/dev/null)
    local finder_show_tabview=$(jq -r '.settings.finder.show_tabview' "$macos_defaults_path" 2>/dev/null)
    
    if [[ -n "$finder_view_style" && "$finder_view_style" != "null" ]]; then
      defaults write com.apple.finder FXPreferredViewStyle -string "$finder_view_style"
    fi
    
    if [[ "$finder_show_sidebar" == "true" ]]; then
      defaults write com.apple.finder ShowSidebar -bool true
    else
      defaults write com.apple.finder ShowSidebar -bool false
    fi
    
    if [[ "$finder_show_tabview" == "true" ]]; then
      defaults write com.apple.finder ShowTabView -bool true
    else
      defaults write com.apple.finder ShowTabView -bool false
    fi
    
    # Springing behavior (scroll to edge effects)
    local springing_enabled=$(jq -r '.settings.springing.enabled' "$macos_defaults_path" 2>/dev/null)
    local springing_delay=$(jq -r '.settings.springing.delay' "$macos_defaults_path" 2>/dev/null)
    
    if [[ "$springing_enabled" == "true" ]]; then
      defaults write NSGlobalDomain com.apple.springing.enabled -bool true
    else
      defaults write NSGlobalDomain com.apple.springing.enabled -bool false
    fi
    
    if [[ -n "$springing_delay" && "$springing_delay" != "null" ]]; then
      defaults write NSGlobalDomain com.apple.springing.delay -string "$springing_delay"
    fi
    
    # Restart Finder and Dock to apply changes
    killall Finder || true
    killall Dock || true
    print_status "macOS preferences configured."
  fi
}

# Cloud tools setup
setup_cloud_tools() {
  local cloud_tools=$(jq -r '.cloud_tools' "$CONFIG_FILE" 2>/dev/null)
  if [[ "$cloud_tools" != "null" ]]; then
    print_header "Cloud Tools Setup"
    
    if [[ $(echo "$cloud_tools" | jq -r '.aws_cli') == "true" ]]; then
      print_info "Configuring AWS CLI..."
      aws configure list &>/dev/null || print_warning "AWS CLI not configured. Run 'aws configure' to set up."
    fi
    
    if [[ $(echo "$cloud_tools" | jq -r '.docker') == "true" ]]; then
      print_info "Docker tools available."
    fi
    
    if [[ $(echo "$cloud_tools" | jq -r '.kubernetes') == "true" ]]; then
      print_info "Kubernetes tools available."
    fi
    
    if [[ $(echo "$cloud_tools" | jq -r '.terraform') == "true" ]]; then
      print_info "Terraform available."
    fi
  fi
}

# Set zsh as default shell
set_zsh_default() {
  print_header "Setting Zsh as Default Shell"
  
  local current_shell=$(echo $SHELL)
  local zsh_path=$(which zsh)
  
  if [[ "$current_shell" != "$zsh_path" ]]; then
    print_info "Setting zsh as default shell..."
    chsh -s "$zsh_path"
    print_status "Zsh set as default shell. Please restart your terminal for changes to take effect."
  else
    print_status "Zsh is already the default shell"
  fi
}

# Final verification
verify_setup() {
  print_header "Final Verification"
  
  # Check symlinks
  print_info "Checking symlinks..."
  local symlink_errors=0
  for file in ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/alacritty/alacritty.toml; do
    if [[ -L "$file" ]]; then
      print_status "$(basename "$file") symlink exists"
    else
      print_error "$(basename "$file") symlink missing"
      ((symlink_errors++))
    fi
  done
  
  # Check scripts
  print_info "Checking scripts..."
  local script_errors=0
  for script in activate gsw gbnew greset help mkcd backup pull-all; do
    if command -v "$script" &>/dev/null; then
      print_status "$script available"
    else
      print_error "$script not found"
      ((script_errors++))
    fi
  done
  
  # Check tmux plugins
  print_info "Checking tmux plugins..."
  if [[ -d ~/.tmux/plugins/tpm ]]; then
    print_status "TPM installed"
  else
    print_error "TPM missing"
    ((script_errors++))
  fi
  
  # Check Homebrew packages
  print_info "Checking Homebrew packages..."
  local package_count=$(brew list | wc -l)
  print_status "$package_count packages installed"
  
  # Summary
  if [[ $symlink_errors -eq 0 && $script_errors -eq 0 ]]; then
    print_status "All checks passed! Setup is complete."
  else
    print_warning "Some issues found. Please check the errors above."
  fi
}

# Show next steps
show_next_steps() {
  print_header "Next Steps"
  echo "  1. Restart your terminal"
  echo "  2. Run 'help' to see available commands"
  echo "  3. Run 'tmux' to test tmux configuration"
  echo "  4. Run 'nvim' to test Neovim setup"
  
  if [[ "$SETUP_TYPE" == "work" ]]; then
    echo "  5. Configure AWS CLI: aws configure"
    echo "  6. Set up SSH keys manually if needed"
  fi
  
  echo -e "\n🎉 Setup complete for $CONFIG_NAME configuration!"
  echo -e "\n💡 If any steps failed, you can run the script again to retry specific parts."
}

# Main setup runner
main() {
  print_header "Dotfiles Installation"
  echo "Welcome to the enhanced dotfiles installer!"
  echo "This script will set up your system based on your chosen configuration."
  
  choose_setup_type
  
  print_header "Starting Installation"
  print_info "Configuration: $CONFIG_NAME"
  print_info "Type: $SETUP_TYPE"
  
  # Run installation steps
  detect_os
  install_nerd_fonts
  install_manual_apps
  setup_dotfiles
  install_additional_tools
  setup_git_config
  setup_ssh
  setup_cloud_tools
  set_zsh_default
  
  # Final steps
  verify_setup
  show_next_steps
}

# Run main function
main
