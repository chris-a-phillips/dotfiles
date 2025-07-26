#!/bin/bash

# Quick Setup Script for Dotfiles
# This script can be run with: curl -fsSL https://raw.githubusercontent.com/chris-a-phillips/dotfiles/main/quick-setup.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

# Check if we're on macOS
check_os() {
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS. Please use the main install.sh script for other operating systems."
    exit 1
  fi
}

# Install Xcode Command Line Tools
install_xcode_tools() {
  print_header "Installing Xcode Command Line Tools"
  
  if ! xcode-select -p &>/dev/null; then
    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    print_warning "Please complete the Xcode Command Line Tools installation in the popup window, then press Enter to continue..."
    read -r
  else
    print_status "Xcode Command Line Tools already installed"
  fi
}

# Clone the dotfiles repository
clone_dotfiles() {
  print_header "Cloning Dotfiles Repository"
  
  DOTFILES_DIR="$HOME/.dotfiles"
  
  if [[ -d "$DOTFILES_DIR" ]]; then
    print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
    echo -e "\nOptions:"
    echo "  y) Update existing dotfiles and continue"
    echo "  n) Use existing dotfiles (may be outdated)"
    echo "  r) Remove existing dotfiles and start fresh"
    echo ""
    read -p "What would you like to do? (y/n/r): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      print_info "Updating existing dotfiles..."
      cd "$DOTFILES_DIR"
      git pull origin main
      print_status "Dotfiles updated"
    elif [[ $REPLY =~ ^[Rr]$ ]]; then
      print_info "Removing existing dotfiles and starting fresh..."
      rm -rf "$DOTFILES_DIR"
      git clone https://github.com/chris-a-phillips/dotfiles.git "$DOTFILES_DIR"
      print_status "Dotfiles cloned fresh"
    else
      print_info "Using existing dotfiles (may be outdated)"
    fi
  else
    print_info "Cloning dotfiles repository..."
    git clone https://github.com/chris-a-phillips/dotfiles.git "$DOTFILES_DIR"
    print_status "Dotfiles cloned successfully"
  fi
}

# Show manual setup instructions
show_manual_setup() {
  print_header "Manual Setup Instructions"
  
  echo -e "\nSince you're running this via curl, input prompts may not work properly."
  echo -e "Please follow these manual steps:\n"
  
  echo "1. Clone the repository manually:"
  echo "   git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles"
  echo ""
  echo "2. Navigate to the directory:"
  echo "   cd ~/.dotfiles"
  echo ""
  echo "3. Run the installer directly:"
  echo "   ./install.sh"
  echo ""
  echo "This will allow you to interact with the setup prompts properly."
}

# Run the main installer
run_installer() {
  print_header "Running Main Installer"
  
  cd "$HOME/.dotfiles"
  
  if [[ -f "install.sh" ]]; then
    print_info "Starting the main installer..."
    chmod +x install.sh
    ./install.sh
  else
    print_error "install.sh not found in dotfiles directory"
    exit 1
  fi
}

# Show completion message
show_completion() {
  print_header "Installation Complete!"
  
  echo -e "\n🎉 Your dotfiles setup is complete!"
  echo -e "\nNext steps:"
  echo "  1. Restart your terminal"
  echo "  2. Run 'help' to see available commands"
  echo "  3. Run 'tmux' to test tmux configuration"
  echo "  4. Run 'nvim' to test Neovim setup"
  echo -e "\nFor more information, visit: https://github.com/chris-a-phillips/dotfiles"
}

# Main function
main() {
  print_header "Dotfiles Quick Setup"
  echo "This script will set up your dotfiles environment on macOS."
  echo ""
  
  # Check OS
  check_os
  
  # Install Xcode tools
  install_xcode_tools
  
  # Check if running via curl
  if [[ -t 0 ]]; then
    # Interactive mode - clone and run installer
    clone_dotfiles
    run_installer
    show_completion
  else
    # Non-interactive mode (via curl) - show manual instructions
    show_manual_setup
  fi
}

# Run main function
main 