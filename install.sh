#!/bin/bash

set -e # Exit if any command fails

# 🟢 Detect OS
detect_os() {
  OS="$(uname)"
  if [[ "$OS" == "Darwin" ]]; then
    echo "🍏 macOS detected."
    install_homebrew
    install_brew_packages
  elif [[ "$OS" == "Linux" ]]; then
    echo "🐧 Linux detected."
    install_linux_packages
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

# 🟢 Run All Setup Steps
main() {
  echo "🚀 Starting full system setup..."
  detect_os
  install_nerd_fonts
  setup_chezmoi
  add_dotfiles_to_chezmoi
  echo "✅ Setup complete! Restart your terminal."
}

# Start the script
main
