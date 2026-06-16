#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
RUN_BREW=1
RUN_PACKAGES=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --no-brew       Skip Homebrew installation and brew bundle on macOS
  --no-packages   Skip platform package installation
  --dry-run       Show what would happen without changing files
  -h, --help      Show this help
EOF
}

log() {
  printf '\033[0;32m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[0;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

is_wsl() {
  [[ "${DOTFILES_FORCE_WSL:-0}" == "1" ]] && return 0
  is_linux && grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    run "$@"
  elif command_exists sudo; then
    run sudo "$@"
  else
    warn "sudo is not available; skipping root command: $*"
    return 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-brew)
        RUN_BREW=0
        ;;
      --no-packages)
        RUN_PACKAGES=0
        RUN_BREW=0
        ;;
      --dry-run)
        DRY_RUN=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

load_homebrew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_xcode_tools() {
  is_macos || return 0

  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools are not installed."
    run xcode-select --install || true
    die "Finish the Apple installer popup, then run ./install.sh again."
  fi
}

ensure_homebrew() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  [[ "$RUN_BREW" -eq 1 ]] || return 0
  is_macos || {
    warn "Homebrew bundle is only automated for macOS; Linux/WSL uses apt where possible."
    return 0
  }

  load_homebrew_shellenv

  if ! command_exists brew; then
    log "Installing Homebrew"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: install Homebrew\n'
      return 0
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    load_homebrew_shellenv
  fi

  command_exists brew || die "Homebrew installation did not put brew on PATH."
}

install_brew_bundle() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  [[ "$RUN_BREW" -eq 1 ]] || return 0
  if ! command_exists brew; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "Installing Homebrew packages from Brewfile"
      run brew bundle --file "$DOTFILES_DIR/Brewfile"
    fi
    return 0
  fi

  log "Installing Homebrew packages from Brewfile"
  run brew bundle --file "$DOTFILES_DIR/Brewfile"
}

install_apt_packages() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  if ! command_exists apt-get; then
    warn "No apt-get found; automated Linux package install currently targets Ubuntu/Debian/WSL."
    return 0
  fi

  local required_packages=(
    build-essential
    ca-certificates
    curl
    direnv
    fd-find
    fzf
    git
    neovim
    pipx
    python3
    python3-pip
    python3-venv
    ripgrep
    ruby-full
    tldr
    tmux
    tree
    unzip
    wl-clipboard
    xclip
    zip
    zsh
  )
  local optional_packages=(
    eza
    git-delta
    tmuxinator
    urlview
  )
  local packages=("${required_packages[@]}")
  local package

  log "Installing Ubuntu/Debian packages"
  run_as_root apt-get update || return 0

  for package in "${optional_packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      packages+=("$package")
    else
      warn "apt package not found in configured sources: $package"
    fi
  done

  run_as_root apt-get install -y "${packages[@]}" || return 0
}

install_linux_cli_extras() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  if command_exists pipx; then
    if ! command_exists llm; then
      log "Installing llm with pipx"
      run pipx install llm || warn "Could not install llm with pipx."
    fi
  else
    warn "pipx is not available; skipping llm install."
  fi
}

install_linux_compat_links() {
  is_linux || return 0

  run mkdir -p "$HOME/.local/bin"

  if ! command_exists fd && [[ -x /usr/bin/fdfind ]]; then
    log "Linking fd to Ubuntu's fdfind binary"
    run ln -sfn /usr/bin/fdfind "$HOME/.local/bin/fd"
  fi

  if ! command_exists delta && command_exists git-delta; then
    log "Linking delta to git-delta"
    run ln -sfn "$(command -v git-delta)" "$HOME/.local/bin/delta"
  fi
}

ensure_wsl_workspace() {
  is_wsl || return 0

  log "Preparing WSL workspace directories"
  run mkdir -p "$HOME/code" "$HOME/scratch"

  case "$DOTFILES_DIR" in
    /mnt/*)
      warn "Dotfiles are running from Windows-mounted storage: $DOTFILES_DIR"
      warn "For better WSL performance, keep active repos under the Linux filesystem, such as $HOME/code."
      ;;
  esac
}

backup_target() {
  local target="$1"
  local relative="${target#$HOME/}"
  local backup="$BACKUP_DIR/$relative"

  run mkdir -p "$(dirname "$backup")"
  run mv "$target" "$backup"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    warn "Would move existing $target to $backup"
  else
    warn "Moved existing $target to $backup"
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  [[ -e "$source" ]] || die "Missing source file: $source"
  run mkdir -p "$(dirname "$target")"

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "$target already linked"
    return 0
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  run ln -sfn "$source" "$target"
  log "Linked $target"
}

install_dotfiles() {
  log "Linking dotfiles"

  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
  link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
  link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  link_file "$DOTFILES_DIR/configs/lazygit/config.yaml" "$HOME/.config/lazygit/config.yml"
  link_file "$DOTFILES_DIR/configs/navi/config.yaml" "$HOME/.config/navi/config.yaml"
  link_file "$DOTFILES_DIR/configs/navi/cheats" "$HOME/.config/navi/cheats"

  if is_macos; then
    link_file "$DOTFILES_DIR/configs/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  fi

  run mkdir -p "$HOME/.config/tmux"
  link_file "$DOTFILES_DIR/tmux/statusline.conf" "$HOME/.config/tmux/statusline.conf"
  link_file "$DOTFILES_DIR/tmux/utility.conf" "$HOME/.config/tmux/utility.conf"
  if is_macos; then
    link_file "$DOTFILES_DIR/tmux/macos.conf" "$HOME/.config/tmux/macos.conf"
  fi
  if is_wsl; then
    link_file "$DOTFILES_DIR/tmux/wsl.conf" "$HOME/.config/tmux/wsl.conf"
  fi

  run mkdir -p "$HOME/.config/tmuxinator"
  local tmuxinator_file
  for tmuxinator_file in "$DOTFILES_DIR"/tmuxinator/*.yml; do
    [[ -f "$tmuxinator_file" ]] || continue
    link_file "$tmuxinator_file" "$HOME/.config/tmuxinator/$(basename "$tmuxinator_file")"
  done
}

write_platform_gitconfig() {
  local target="$HOME/.gitconfig.platform"

  if [[ -f "$target" ]]; then
    log "$target already exists"
    return 0
  fi

  if is_macos; then
    log "Writing macOS git credential helper config"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: create %s with osxkeychain helper\n' "$target"
    else
      cat > "$target" <<'EOF'
[credential]
	helper = osxkeychain
EOF
    fi
  elif is_wsl; then
    log "Writing WSL git credential helper note"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: create %s for WSL git settings\n' "$target"
    else
      cat > "$target" <<'EOF'
# Machine-specific WSL git settings can live here.
# If Git Credential Manager is available through Windows Git, configure it in
# ~/.dotfiles/.local.zsh or this file after confirming the work laptop policy.
EOF
    fi
  else
    log "Writing Linux git credential helper config"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: create %s with cache helper\n' "$target"
    else
      cat > "$target" <<'EOF'
[credential]
	helper = cache --timeout=3600
EOF
    fi
  fi
}

install_scripts() {
  log "Installing helper scripts into ~/bin"
  run mkdir -p "$HOME/bin"

  local script
  for script in "$DOTFILES_DIR"/scripts/*; do
    [[ -f "$script" ]] || continue
    run install -m 755 "$script" "$HOME/bin/$(basename "$script")"
  done
}

install_shell_extras() {
  if [[ ! -d "$HOME/powerlevel10k" ]] && command_exists git; then
    log "Installing Powerlevel10k"
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
  fi

  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]] && command_exists git; then
    log "Installing tmux plugin manager"
    run git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  fi
}

ensure_local_files() {
  write_platform_gitconfig

  if [[ ! -f "$HOME/.dotfiles/.local.zsh" ]]; then
    log "Creating local shell override file"
    run touch "$HOME/.dotfiles/.local.zsh"
  fi

  if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    log "Creating local git identity file"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: create %s\n' "$HOME/.gitconfig.local"
    else
      cat > "$HOME/.gitconfig.local" <<'EOF'
[user]
	name =
	email =
EOF
      warn "Fill in ~/.gitconfig.local with the name and email for this machine."
    fi
  fi
}

warn_missing_tools() {
  [[ "$DRY_RUN" -eq 0 ]] || return 0

  local missing=()
  local tool

  for tool in zsh git nvim tmux lazygit navi rg fd fzf delta llm tmuxinator direnv; do
    command_exists "$tool" || missing+=("$tool")
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    warn "Missing optional tools after install: ${missing[*]}"
    if is_wsl; then
      warn "On a managed Windows laptop, install these through apt, pipx, gem, GitHub releases, Linuxbrew, or approved company package sources."
    fi
  fi
}

verify_install() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run complete"
    return 0
  fi

  log "Verifying core links"
  local target
  for target in "$HOME/.zshrc" "$HOME/.aliases" "$HOME/.gitconfig" "$HOME/.tmux.conf"; do
    [[ -L "$target" ]] || die "$target is not linked"
  done

  log "Done"
  printf '\nNext steps:\n'
  printf '  1. Edit ~/.gitconfig.local with this machine'\''s git identity.\n'
  printf '  2. Put secrets or work-only paths in ~/.dotfiles/.local.zsh.\n'
  printf '  3. Restart your terminal.\n'
  printf '  4. In tmux, press prefix + I to install plugins.\n'
  if is_wsl; then
    printf '  5. On Windows, set your terminal profile to this WSL distribution.\n'
  fi
}

main() {
  parse_args "$@"
  ensure_xcode_tools
  ensure_homebrew
  install_brew_bundle
  install_apt_packages
  install_linux_cli_extras
  install_linux_compat_links
  ensure_wsl_workspace
  install_dotfiles
  install_scripts
  install_shell_extras
  ensure_local_files
  warn_missing_tools
  verify_install
}

main "$@"
