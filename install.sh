#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
RUN_BREW=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --no-brew     Skip Homebrew installation and brew bundle
  --dry-run     Show what would happen without changing files
  -h, --help    Show this help
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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-brew)
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
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  if ! xcode-select -p >/dev/null 2>&1; then
    warn "Xcode Command Line Tools are not installed."
    run xcode-select --install || true
    die "Finish the Apple installer popup, then run ./install.sh again."
  fi
}

ensure_homebrew() {
  [[ "$RUN_BREW" -eq 1 ]] || return 0
  [[ "$(uname -s)" == "Darwin" ]] || {
    warn "Homebrew bundle is only automated for macOS right now."
    return 0
  }

  load_homebrew_shellenv

  if ! command_exists brew; then
    log "Installing Homebrew"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: install Homebrew\n'
    else
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    load_homebrew_shellenv
  fi

  command_exists brew || die "Homebrew installation did not put brew on PATH."
}

install_brew_bundle() {
  [[ "$RUN_BREW" -eq 1 ]] || return 0
  command_exists brew || return 0

  log "Installing Homebrew packages from Brewfile"
  run brew bundle --file "$DOTFILES_DIR/Brewfile"
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
  link_file "$DOTFILES_DIR/configs/ghostty/config.ghostty" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  link_file "$DOTFILES_DIR/configs/lazygit/config.yaml" "$HOME/.config/lazygit/config.yml"
  link_file "$DOTFILES_DIR/configs/navi/config.yaml" "$HOME/.config/navi/config.yaml"
  link_file "$DOTFILES_DIR/configs/navi/cheats" "$HOME/.config/navi/cheats"

  run mkdir -p "$HOME/.config/tmux"
  link_file "$DOTFILES_DIR/tmux/statusline.conf" "$HOME/.config/tmux/statusline.conf"
  link_file "$DOTFILES_DIR/tmux/utility.conf" "$HOME/.config/tmux/utility.conf"
  link_file "$DOTFILES_DIR/tmux/macos.conf" "$HOME/.config/tmux/macos.conf"
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
}

main() {
  parse_args "$@"
  ensure_xcode_tools
  ensure_homebrew
  install_brew_bundle
  install_dotfiles
  install_scripts
  install_shell_extras
  ensure_local_files
  verify_install
}

main "$@"
