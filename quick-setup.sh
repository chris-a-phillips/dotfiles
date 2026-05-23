#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/chris-a-phillips/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-develop}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

log() {
  printf '\033[0;32m==>\033[0m %s\n' "$*"
}

die() {
  printf '\033[0;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "quick-setup.sh is intended for macOS. Clone the repo and run ./install.sh manually on other systems."
fi

if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools"
  xcode-select --install || true
  die "Finish the Apple installer popup, then rerun this script."
fi

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  log "Updating $DOTFILES_DIR"
  git -C "$DOTFILES_DIR" fetch origin "$DOTFILES_BRANCH"
  git -C "$DOTFILES_DIR" checkout "$DOTFILES_BRANCH"
  git -C "$DOTFILES_DIR" pull --ff-only origin "$DOTFILES_BRANCH"
else
  log "Cloning dotfiles"
  git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

log "Running installer"
"$DOTFILES_DIR/install.sh"
