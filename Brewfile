# Brewfile (latest-focused)
# - Keep unversioned formulae where possible (tracks latest)
# - Keep nvm/pyenv for version management, but DO NOT install old runtimes via Brewfile

tap "homebrew/bundle"
tap "homebrew/services"
tap "mongodb/brew"
tap "wvanlint/twf"

# Modern replacement for ls
brew "eza"
# Play, record, convert, and stream audio and video
brew "ffmpeg"
# Banner-like program prints strings as ASCII art
brew "figlet"
# Command-line fuzzy finder written in Go
brew "fzf"
# Distributed revision control system
brew "git"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Simple terminal UI for git commands
brew "lazygit"
# Access large language models from the command-line
brew "llm"
# Rainbows and unicorns in your console!
brew "lolcat"

# Open-source, cross-platform JavaScript runtime environment (latest)
brew "node"
# Manage multiple Node.js versions
brew "nvm"

# Interpreted, interactive, object-oriented programming language (latest)
brew "python"
# Python version management
brew "pyenv"
# Python dependency management tool
brew "pipenv"
# Tool for creating isolated virtual python environments
brew "virtualenv"

# MongoDB Shell to connect, configure, query, and work with your MongoDB database
brew "mongosh"
# High-performance, schema-free, document-oriented database
brew "mongodb/brew/mongodb-community"

# Cross platform, open source .NET development framework
brew "mono"
# Interactive cheatsheet tool for the command-line
brew "navi"
# Ambitious Vim-fork focused on extensibility and agility
brew "neovim"

# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Command-line deletion tool focused on safety, ergonomics, and performance
brew "rm-improved"
# Simplified and community-driven man pages
brew "tldr"
# Terminal multiplexer
brew "tmux"
# Manage complex tmux sessions easily
brew "tmuxinator"
# Display directories as trees (with optional color/HTML output)
brew "tree"

# PostgreSQL (latest you want)
brew "postgresql", restart_service: :changed, link: true

# Standalone tree view file explorer, inspired by fzf
brew "wvanlint/twf/twf", args: ["HEAD"]

# Enable Windows-like alt-tab
cask "alt-tab"
cask "font-hack-nerd-font"
cask "ghostty"
# Utility to hide menu bar items
cask "hiddenbar"
# Menu bar calendar
cask "itsycal"
