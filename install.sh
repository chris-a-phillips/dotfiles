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

# Dotfiles + Neovim
setup_chezmoi() {
  echo -e "\n💾 Applying chezmoi dotfiles..."
  if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    chezmoi init --apply git@github.com:yourusername/dotfiles.git
  else
    chezmoi apply
  fi
}

add_dotfiles_to_chezmoi() {
  echo -e "\n🛠 Ensuring all dotfiles are added to chezmoi..."
  FILES_TO_ADD=(
    "$HOME/.tmux.conf" "$HOME/.zshrc" "$HOME/.gitconfig"
    "$HOME/.config/alacritty/alacritty.yml" "$HOME/.config/nvim"
  )
  for file in "${FILES_TO_ADD[@]}"; do
    [ -e "$file" ] && chezmoi add "$file" || echo "⚠️ Skipping $file"
  done
  chezmoi apply
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
  confirm_step "Apply chezmoi dotfiles?" && run_with_spinner setup_chezmoi
  confirm_step "Add local dotfiles to chezmoi?" && run_with_spinner add_dotfiles_to_chezmoi
  confirm_step "Set up Git config?" && run_with_spinner setup_git_config
  confirm_step "Set up SSH keys?" && run_with_spinner setup_ssh
  echo -e "\n✅ Setup complete! Restart your terminal."
}

main
