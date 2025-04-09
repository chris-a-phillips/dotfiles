#!/bin/bash

set -e # Exit if any command fails

# 🟢 Ask for Personal or Work Setup
choose_setup_type() {
  echo "💻 Is this a Personal or Work computer?"
  select choice in "Personal" "Work"; do
    case $choice in
    Personal)
      setup_type="personal"
      break
      ;;
    Work)
      setup_type="work"
      break
      ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
    esac
  done
}

# 🟢 Ask Before Running a Step
confirm_step() {
  echo "$1 (y/n)?"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    return 0 # Proceed
  else
    return 1 # Skip
  fi
}

# 🟢 Detect OS
detect_os() {
  OS="$(uname)"
  if [[ "$OS" == "Darwin" ]]; then
    echo "🍏 macOS detected."
    confirm_step "Install Homebrew?" && install_homebrew
    confirm_step "Install Brew packages?" && install_brew_packages
  elif [[ "$OS" == "Linux" ]]; then
    echo "🐧 Linux detected."
    confirm_step "Install Linux packages?" && install_linux_packages
  else
    echo "❌ Unsupported OS: $OS"
    exit 1
  fi
}

# 🟢 Install Homebrew (macOS)
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew update
}

# 🟢 Install Brew Packages from Brewfile
install_brew_packages() {
  echo "📦 Installing apps from Brewfile..."
  brew bundle --file="$HOME/.dotfiles/Brewfile"
}

# 🟢 Install Linux Packages
install_linux_packages() {
  if command -v apt &>/dev/null; then
    sudo apt update
    xargs -a "$HOME/.dotfiles/packages.txt" sudo apt install -y
  elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm $(cat "$HOME/.dotfiles/packages.txt")
  fi
}

# 🟢 Install Nerd Fonts
install_nerd_fonts() {
  echo "💾 Installing Additional Nerd Fonts..."
  mkdir -p ~/Library/Fonts
  cd ~/Library/Fonts
  while IFS= read -r font_url; do
    font_name=$(basename "$font_url" .zip)
    curl -fLo "${font_name}.zip" "$font_url"
    unzip "${font_name}.zip" -d "$font_name"
    rm "${font_name}.zip"
  done <"$HOME/.dotfiles/fonts.txt"
}

# 🟢 Set Up Chezmoi and Apply Dotfiles
setup_chezmoi() {
  echo "💾 Applying chezmoi dotfiles..."
  if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    chezmoi init --apply yourusername # Change to your GitHub username
  else
    chezmoi apply
  fi
}

# 🟢 Ensure All Dotfiles Are Added to Chezmoi
add_dotfiles_to_chezmoi() {
  echo "🛠 Ensuring all dotfiles are added to chezmoi..."
  FILES_TO_ADD=(
    "$HOME/.tmux.conf"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.config/alacritty/alacritty.yml"
    "$HOME/.config/nvim"
  )

  for file in "${FILES_TO_ADD[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
      chezmoi add "$file"
    else
      echo "⚠️  Skipping $file (not found)"
    fi
  done

  chezmoi apply
}

# 🟢 Install Additional Mac Apps Based on Setup Type
install_extra_apps() {
  echo "📦 Installing additional macOS apps for $setup_type setup..."

  if [[ "$setup_type" == "personal" ]]; then
    brew install --cask rectangle raycast discord slack spotify
    #TODO: make sure to intall alacritty this way: brew install --cask alacritty --no-quarantine
  elif [[ "$setup_type" == "work" ]]; then
    brew install --cask zoom microsoft-teams docker iterm2
  fi
}

# 🟢 Install Programming Languages
install_languages() {
  echo "🛠 Installing programming languages..."
  brew install python node rust go
}

# 🟢 Apply macOS Defaults
set_macos_defaults() {
  echo "🛠 Configuring macOS system preferences..."
  # TODO: turn off monitor control keyboard shortcuts
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.1
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
  defaults write com.apple.finder AppleShowAllFiles -bool true
  killall Finder
  echo "✅ macOS preferences configured!"
}

# 🟢 Run All Setup Steps
main() {
  echo "🚀 Starting full system setup..."
  choose_setup_type
  confirm_step "Detect OS and install system packages?" && detect_os
  confirm_step "Install Nerd Fonts?" && install_nerd_fonts
  confirm_step "Install extra apps?" && install_extra_apps
  confirm_step "Install programming languages?" && install_languages
  confirm_step "Set macOS defaults?" && set_macos_defaults
  confirm_step "Apply chezmoi dotfiles?" && setup_chezmoi
  confirm_step "Add dotfiles to chezmoi?" && add_dotfiles_to_chezmoi
  echo "✅ Setup complete! Restart your terminal."
}

# Start the script
main
