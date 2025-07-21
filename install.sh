#!/bin/bash

set -e  # Exit on error

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

# Ask Personal or Work
choose_setup_type() {
  echo -e "\n💻 Is this a Personal or Work computer?"
  select choice in "Personal" "Work"; do
    case $choice in
      Personal) setup_type="personal"; break ;;
      Work) setup_type="work"; break ;;
      *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# Confirm Before Step
confirm_step() {
  echo -e "\n🔹 $1 (y/n)?"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# OS Detection and Package Install
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
}

install_brew_packages() {
  echo "📦 Installing apps from Brewfile..."
  local BREWFILE="$HOME/.dotfiles/Brewfile"
  brew bundle --file="$BREWFILE"
}

install_linux_packages() {
  if command -v apt &>/dev/null; then
    sudo apt update
    xargs -a "$HOME/.dotfiles/packages.txt" sudo apt install -y
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm $(cat "$HOME/.dotfiles/packages.txt")
  fi
}

detect_os() {
  OS="$(uname)"
  echo -e "\n🔍 Detecting OS..."
  case $OS in
    Darwin)
      echo "🍏 macOS detected."
      confirm_step "Install Homebrew?" && run_with_spinner install_homebrew
      confirm_step "Install Brew packages?" && run_with_spinner install_brew_packages
      ;;
    Linux)
      echo "🐧 Linux detected."
      confirm_step "Install Linux packages?" && run_with_spinner install_linux_packages
      ;;
    *)
      echo "❌ Unsupported OS: $OS"
      exit 1
      ;;
  esac
}

# Fonts
install_nerd_fonts() {
  echo -e "\n💾 Installing Nerd Fonts..."
  FONT_DIR="$HOME/Library/Fonts"
  [[ "$(uname)" == "Linux" ]] && FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  while IFS= read -r font_url; do
    font_name=$(basename "$font_url" .zip)
    curl -fLo "$font_name.zip" "$font_url"
    unzip -o "$font_name.zip" -d "$FONT_DIR"
    rm "$font_name.zip"
  done < "$HOME/.dotfiles/fonts.txt"
  echo "✅ Fonts installed."
}

# GUI Apps + Configs
install_manual_apps() {
  echo -e "\n📥 Installing manually managed apps..."
  brew install --cask \
    visual-studio-code postman iterm2 notion zoom giphy-capture \
    clipy raycast numi monitorcontrol dropzone amphetamine \
    itsycal alt-tab rectangle-pro dockutil hiddenbar \
    background-music spotify obsidian db-browser-for-sqlite

  echo "✅ GUI apps installed."

  # Raycast
  RAYCAST_BACKUP="$HOME/.dotfiles/app_configs/raycast"
  if [[ -d "$RAYCAST_BACKUP" ]]; then
    echo "🗂 Restoring Raycast settings..."
    mkdir -p "$HOME/Library/Application Support/com.raycast.macos"
    cp -R "$RAYCAST_BACKUP"/* "$HOME/Library/Application Support/com.raycast.macos/"
  fi

  # Rectangle Pro
  RECTANGLE_PLIST="$HOME/.dotfiles/app_configs/rectangle-pro/com.knollsoft.Rectangle-Pro.plist"
  if [[ -f "$RECTANGLE_PLIST" ]]; then
    echo "🗂 Restoring Rectangle Pro settings..."
    mkdir -p "$HOME/Library/Preferences"
    cp "$RECTANGLE_PLIST" "$HOME/Library/Preferences/"
    defaults import com.knollsoft.Rectangle-Pro "$RECTANGLE_PLIST"
  fi
}

# Git Config
setup_git_config() {
  echo -e "\n🔧 Setting up Git configuration..."
  if ! git config --global user.name >/dev/null; then
    read -p "🪪 Git user name: " git_name
    git config --global user.name "$git_name"
  fi
  if ! git config --global user.email >/dev/null; then
    read -p "📧 Git user email: " git_email
    git config --global user.email "$git_email"
  fi
  [ -f "$HOME/.gitignore_global" ] && \
    git config --global core.excludesfile "$HOME/.gitignore_global"
  [[ "$(uname)" == "Darwin" ]] && \
    git config --global credential.helper osxkeychain
  echo "✅ Git is configured."
}

# SSH Setup
setup_ssh() {
  echo -e "\n🔐 Checking SSH key setup..."
  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$HOME/.ssh/id_ed25519" -N ""
  fi
  eval "$(ssh-agent -s)"
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
  echo "🔑 Public key:\n"
  cat ~/.ssh/id_ed25519.pub
  echo "📋 Copy this to GitHub: https://github.com/settings/ssh/new"
}

# Dotfiles Setup
setup_dotfiles() {
  echo -e "\n💾 Setting up dotfiles symlinks..."
  
  # Backup existing dotfiles if they exist and aren't already symlinks
  backup_dotfile() {
    local file="$1"
    if [[ -f "$file" && ! -L "$file" ]]; then
      echo "📦 Backing up existing $file to ${file}.backup"
      mv "$file" "${file}.backup"
    fi
  }
  
  # Create symlinks for core dotfiles
  backup_dotfile ~/.zshrc
  backup_dotfile ~/.gitconfig
  backup_dotfile ~/.aliases
  backup_dotfile ~/.p10k.zsh
  backup_dotfile ~/.tmux.conf
  
  ln -sf ~/.dotfiles/.zshrc ~/.zshrc
  ln -sf ~/.dotfiles/.gitconfig ~/.gitconfig
  ln -sf ~/.dotfiles/.aliases ~/.aliases
  ln -sf ~/.dotfiles/.p10k.zsh ~/.p10k.zsh
  
  # Create config directories and symlinks
  mkdir -p ~/.config
  mkdir -p ~/.config/alacritty
  mkdir -p ~/.config/tmux
  
  # Handle alacritty config (TOML format)
  if [[ -f ~/.dotfiles/alacritty/alacritty.toml ]]; then
    ln -sf ~/.dotfiles/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
  fi
  
  # Handle tmux config and related files
  ln -sf ~/.dotfiles/tmux/tmux.conf ~/.tmux.conf
  ln -sf ~/.dotfiles/tmux/statusline.conf ~/.config/tmux/statusline.conf
  ln -sf ~/.dotfiles/tmux/utility.conf ~/.config/tmux/utility.conf
  ln -sf ~/.dotfiles/tmux/macos.conf ~/.config/tmux/macos.conf
  
  # Add custom scripts to PATH
  mkdir -p ~/bin
  if [ -d ~/.dotfiles/scripts ]; then
    # Remove existing scripts to avoid conflicts
    rm -rf ~/bin/* 2>/dev/null || true
    cp -r ~/.dotfiles/scripts/* ~/bin/
    chmod +x ~/bin/*
    echo "✅ Scripts copied to ~/bin and made executable"
  else
    echo "⚠️ No scripts directory found"
  fi
  
  echo "✅ Dotfiles symlinks created."
}

install_additional_tools() {
  echo -e "\n🛠 Installing additional development tools..."
  
  # Install Neovim and LazyVim
  if command -v nvim &>/dev/null; then
    echo "📦 Installing LazyVim..."
    if [ ! -d ~/.config/nvim ]; then
      git clone https://github.com/LazyVim/starter ~/.config/nvim
      rm -rf ~/.config/nvim/.git 2>/dev/null || true
    else
      echo "⚠️ Neovim config already exists"
    fi
  else
    echo "⚠️ Neovim not found, install with: brew install neovim"
  fi
  
  # Install Powerlevel10k theme
  if [ ! -d ~/powerlevel10k ]; then
    echo "📦 Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
  else
    echo "⚠️ Powerlevel10k already installed"
  fi
  
  # Install Tmux Plugin Manager (TPM)
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    echo "📦 Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    echo "⚠️ TPM already installed"
  fi
  
  echo "✅ Additional tools installed."
}

install_languages() {
  echo -e "\n🛠 Installing programming languages..."
  brew install python node rust go
}

set_macos_defaults() {
  echo -e "\n🛠 Configuring macOS system preferences..."
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.1
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write com.apple.finder AppleShowAllFiles -bool true
  killall Finder || true
  echo "✅ macOS preferences configured."
}

# Main setup runner
main() {
  echo -e "\n🚀 Starting full system setup..."
  choose_setup_type
  confirm_step "Detect OS and install system packages?" && run_with_spinner detect_os
  confirm_step "Install Nerd Fonts?" && run_with_spinner install_nerd_fonts
  confirm_step "Install manual GUI apps?" && run_with_spinner install_manual_apps
  confirm_step "Install programming languages?" && run_with_spinner install_languages
  confirm_step "Set macOS defaults?" && run_with_spinner set_macos_defaults
  confirm_step "Set up dotfiles symlinks?" && run_with_spinner setup_dotfiles
  confirm_step "Install additional development tools?" && run_with_spinner install_additional_tools
  confirm_step "Set up Git config?" && run_with_spinner setup_git_config
  confirm_step "Set up SSH keys?" && run_with_spinner setup_ssh
  
  # Final verification
  echo -e "\n🔍 Final verification..."
  
  # Check symlinks
  echo "Checking symlinks..."
  local symlink_errors=0
  for file in ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/alacritty/alacritty.toml; do
    if [[ -L "$file" ]]; then
      echo "✅ $(basename "$file") symlink exists"
    else
      echo "❌ $(basename "$file") symlink missing"
      ((symlink_errors++))
    fi
  done
  
  # Check scripts
  echo "Checking scripts..."
  local script_errors=0
  for script in activate gsw gbnew help mkcd backup pull-all; do
    if command -v "$script" &>/dev/null; then
      echo "✅ $script available"
    else
      echo "❌ $script not found"
      ((script_errors++))
    fi
  done
  
  # Check tmux plugins
  echo "Checking tmux plugins..."
  if [[ -d ~/.tmux/plugins/tpm ]]; then
    echo "✅ TPM installed"
  else
    echo "❌ TPM missing"
    ((script_errors++))
  fi
  
  # Check Homebrew packages
  echo "Checking Homebrew packages..."
  local package_count=$(brew list | wc -l)
  echo "📦 $package_count packages installed"
  
  # Summary
  if [[ $symlink_errors -eq 0 && $script_errors -eq 0 ]]; then
    echo -e "\n🎉 All checks passed! Setup is complete."
  else
    echo -e "\n⚠️ Some issues found. Please check the errors above."
  fi
  
  echo -e "\n💡 Next steps:"
  echo "  1. Restart your terminal"
  echo "  2. Run 'help' to see available commands"
  echo "  3. Run 'tmux' to test tmux configuration"
  echo "  4. Run 'nvim' to test Neovim setup"
}

main
