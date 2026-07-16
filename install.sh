#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
RUN_BREW=1
RUN_PACKAGES=1
DRY_RUN=0
NEOVIM_FALLBACK_VERSION="${DOTFILES_NEOVIM_FALLBACK_VERSION:-v0.12.3}"
TMUX_FALLBACK_VERSION="${DOTFILES_TMUX_FALLBACK_VERSION:-3.6b}"
LAZYGIT_FALLBACK_VERSION="${DOTFILES_LAZYGIT_FALLBACK_VERSION:-v0.62.2}"
NAVI_FALLBACK_VERSION="${DOTFILES_NAVI_FALLBACK_VERSION:-v2.24.0}"
NVM_FALLBACK_VERSION="${DOTFILES_NVM_FALLBACK_VERSION:-v0.40.3}"
TREE_SITTER_FALLBACK_VERSION="${DOTFILES_TREE_SITTER_FALLBACK_VERSION:-v0.25.10}"
NVIM_CONFIG_REPO="${DOTFILES_NVIM_REPO:-https://github.com/chris-a-phillips/lazyvim.git}"
NVIM_CONFIG_BRANCH="${DOTFILES_NVIM_BRANCH:-main}"
NODE_VERSION="${DOTFILES_NODE_VERSION:-}"

# Make user-local tools visible during install runs, even before zsh startup
# files have been sourced.
export PATH="$HOME/.local/bin:$HOME/.local/bin-personal:$HOME/bin:$PATH"

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

github_latest_tag() {
  local repo="$1"
  command_exists curl || return 1

  local response
  response="$(curl -fsSL --connect-timeout 5 --max-time 15 --retry 1 -H 'Accept: application/vnd.github+json' -H 'User-Agent: chris-a-phillips-dotfiles' "https://api.github.com/repos/$repo/releases/latest")" || return 1
  printf '%s\n' "$response" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

resolve_github_version() {
  local override="$1" repo="$2" fallback="$3" label="$4"
  if [[ -n "$override" ]]; then
    printf '%s\n' "$override"
    return 0
  fi

  local latest
  latest="$(github_latest_tag "$repo" 2>/dev/null || true)"
  if [[ -n "$latest" ]]; then
    printf '%s\n' "$latest"
  else
    warn "Could not resolve the latest $label release; using known-good $fallback."
    printf '%s\n' "$fallback"
  fi
}

download_github_release_asset() {
  local repo="$1" selected="$2" selected_asset="$3" fallback="$4" fallback_asset="$5" destination="$6" label="$7"
  local selected_url fallback_url
  selected_url="https://github.com/$repo/releases/download/$selected/$selected_asset"
  fallback_url="https://github.com/$repo/releases/download/$fallback/$fallback_asset"
  DOWNLOADED_VERSION="$selected"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: download %s from %s\n' "$label" "$selected_url"
    return 0
  fi

  if curl -fL --retry 2 --connect-timeout 10 --max-time 600 "$selected_url" -o "$destination"; then
    return 0
  fi

  if [[ "$selected" == "$fallback" ]]; then
    return 1
  fi

  warn "Could not download $label $selected; falling back to $fallback."
  curl -fL --retry 2 --connect-timeout 10 --max-time 600 "$fallback_url" -o "$destination"
  DOWNLOADED_VERSION="$fallback"
}

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

linux_release_arch() {
  case "$(uname -m)" in
    x86_64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    *) warn "Unsupported Linux architecture for release binaries: $(uname -m)"; return 1 ;;
  esac
}

is_wsl() {
  [[ "${DOTFILES_FORCE_WSL:-0}" == "1" ]] && return 0
  is_linux && grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null
}

platform_name() {
  if is_macos; then
    printf 'macos\n'
  elif is_wsl; then
    printf 'wsl\n'
  elif is_linux; then
    printf 'linux\n'
  else
    printf 'unknown\n'
  fi
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
  is_macos || return 0
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
    bison
    ca-certificates
    curl
    direnv
    fd-find
    fzf
    git
    golang-go
    neovim
    libevent-dev
    ncurses-dev
    nodejs
    npm
    pipx
    pkg-config
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
  local available_packages=()
  local package

  log "Installing Ubuntu/Debian packages"
  if ! run_as_root apt-get update; then
    warn "apt-get update failed; continuing with release-based installers where possible."
    return 0
  fi

  for package in "${required_packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      available_packages+=("$package")
    else
      warn "Required apt package not found in configured sources: $package"
    fi
  done

  for package in "${optional_packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      available_packages+=("$package")
    else
      warn "Optional apt package not found in configured sources: $package"
    fi
  done

  if [[ "${#available_packages[@]}" -eq 0 ]]; then
    warn "No requested apt packages are available."
    return 0
  fi

  if ! run_as_root apt-get install -y "${available_packages[@]}"; then
    warn "Bulk apt installation failed; retrying packages individually."
    for package in "${available_packages[@]}"; do
      run_as_root apt-get install -y "$package" || warn "Could not install apt package: $package"
    done
  fi
}

install_linux_neovim_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  local arch version archive fallback_archive install_root install_dir tmp_dir
  arch="$(linux_release_arch || true)"
  [[ -n "$arch" ]] || return 0
  version="$(resolve_github_version "${DOTFILES_NEOVIM_VERSION:-}" neovim/neovim "$NEOVIM_FALLBACK_VERSION" Neovim)"
  archive="nvim-linux-${arch}.tar.gz"
  fallback_archive="nvim-linux-${arch}.tar.gz"
  install_root="$HOME/.local/opt"
  install_dir="$install_root/nvim-linux-${arch}-${version}"

  if [[ -x "$HOME/.local/bin/nvim" ]] && "$HOME/.local/bin/nvim" --version | head -n 1 | grep -q "${version#v}"; then
    log "Neovim ${version} already installed in ~/.local"
    return 0
  fi

  log "Installing Neovim ${version} into ~/.local"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    download_github_release_asset neovim/neovim "$version" "$archive" "$NEOVIM_FALLBACK_VERSION" "$fallback_archive" /tmp/neovim.tar.gz Neovim
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run mkdir -p "$install_root" "$HOME/.local/bin"
  download_github_release_asset neovim/neovim "$version" "$archive" "$NEOVIM_FALLBACK_VERSION" "$fallback_archive" "$tmp_dir/$archive" Neovim
  version="$DOWNLOADED_VERSION"
  install_dir="$install_root/nvim-linux-${arch}-${version}"
  run tar -xzf "$tmp_dir/$archive" -C "$tmp_dir"
  run rm -rf "$install_dir"
  run mv "$tmp_dir/nvim-linux-${arch}" "$install_dir"
  run ln -sfn "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
}

install_linux_tmux_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  local version archive fallback_archive tmp_dir
  version="$(resolve_github_version "${DOTFILES_TMUX_VERSION:-}" tmux/tmux "$TMUX_FALLBACK_VERSION" tmux)"
  archive="tmux-${version}.tar.gz"
  fallback_archive="tmux-${TMUX_FALLBACK_VERSION}.tar.gz"

  if command_exists tmux && tmux -V | grep -q "tmux ${version}"; then
    log "tmux ${version} already installed"
    return 0
  fi

  log "Installing tmux ${version} into ~/.local"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    download_github_release_asset tmux/tmux "$version" "$archive" "$TMUX_FALLBACK_VERSION" "$fallback_archive" /tmp/tmux.tar.gz tmux
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  download_github_release_asset tmux/tmux "$version" "$archive" "$TMUX_FALLBACK_VERSION" "$fallback_archive" "$tmp_dir/$archive" tmux
  version="$DOWNLOADED_VERSION"
  run tar -xzf "$tmp_dir/$archive" -C "$tmp_dir"
  (
    cd "$tmp_dir/tmux-${version}"
    run ./configure --prefix="$HOME/.local"
    run make -j"$(nproc)"
    run make install
  )
}

install_linux_lazygit_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  local arch version plain_version fallback_plain archive fallback_archive tmp_dir
  arch="$(linux_release_arch || true)"
  [[ -n "$arch" ]] || return 0
  version="$(resolve_github_version "${DOTFILES_LAZYGIT_VERSION:-}" jesseduffield/lazygit "$LAZYGIT_FALLBACK_VERSION" lazygit)"
  plain_version="${version#v}"
  fallback_plain="${LAZYGIT_FALLBACK_VERSION#v}"
  archive="lazygit_${plain_version}_linux_${arch}.tar.gz"
  fallback_archive="lazygit_${fallback_plain}_linux_${arch}.tar.gz"

  if command_exists lazygit && lazygit --version | grep -q "version=${plain_version}"; then
    log "lazygit ${version} already installed"
    return 0
  fi

  log "Installing lazygit ${version} into ~/.local"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    download_github_release_asset jesseduffield/lazygit "$version" "$archive" "$LAZYGIT_FALLBACK_VERSION" "$fallback_archive" /tmp/lazygit.tar.gz lazygit
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run mkdir -p "$HOME/.local/bin"
  download_github_release_asset jesseduffield/lazygit "$version" "$archive" "$LAZYGIT_FALLBACK_VERSION" "$fallback_archive" "$tmp_dir/$archive" lazygit
  run tar -xzf "$tmp_dir/$archive" -C "$tmp_dir"
  run install -m 755 "$tmp_dir/lazygit" "$HOME/.local/bin/lazygit"
}

install_linux_navi_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  local arch target version archive fallback_archive tmp_dir
  arch="$(linux_release_arch || true)"
  [[ -n "$arch" ]] || return 0
  case "$arch" in
    x86_64) target="x86_64-unknown-linux-musl" ;;
    arm64) target="aarch64-unknown-linux-gnu" ;;
  esac
  version="$(resolve_github_version "${DOTFILES_NAVI_VERSION:-}" denisidoro/navi "$NAVI_FALLBACK_VERSION" Navi)"
  archive="navi-${version}-${target}.tar.gz"
  fallback_archive="navi-${NAVI_FALLBACK_VERSION}-${target}.tar.gz"

  if command_exists navi && navi --version | grep -q "${version#v}"; then
    log "Navi ${version} already installed"
    return 0
  fi

  log "Installing Navi ${version} into ~/.local"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    download_github_release_asset denisidoro/navi "$version" "$archive" "$NAVI_FALLBACK_VERSION" "$fallback_archive" /tmp/navi.tar.gz Navi
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run mkdir -p "$HOME/.local/bin"
  download_github_release_asset denisidoro/navi "$version" "$archive" "$NAVI_FALLBACK_VERSION" "$fallback_archive" "$tmp_dir/$archive" Navi
  run tar -xzf "$tmp_dir/$archive" -C "$tmp_dir"
  run install -m 755 "$tmp_dir/navi" "$HOME/.local/bin/navi"
}

install_linux_tree_sitter_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  local arch asset_arch version asset tmp_dir
  arch="$(linux_release_arch || true)"
  [[ -n "$arch" ]] || return 0
  case "$arch" in
    x86_64) asset_arch="x64" ;;
    arm64) asset_arch="arm64" ;;
  esac

  version="$(resolve_github_version "${DOTFILES_TREE_SITTER_VERSION:-}" tree-sitter/tree-sitter "$TREE_SITTER_FALLBACK_VERSION" "Tree-sitter CLI")"
  asset="tree-sitter-linux-${asset_arch}.gz"

  if command_exists tree-sitter && tree-sitter --version | grep -q "${version#v}"; then
    log "Tree-sitter CLI ${version} already installed"
    return 0
  fi

  log "Installing Tree-sitter CLI ${version} into ~/.local"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    download_github_release_asset tree-sitter/tree-sitter "$version" "$asset" "$TREE_SITTER_FALLBACK_VERSION" "$asset" /tmp/tree-sitter.gz "Tree-sitter CLI"
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN
  run mkdir -p "$HOME/.local/bin"
  download_github_release_asset tree-sitter/tree-sitter "$version" "$asset" "$TREE_SITTER_FALLBACK_VERSION" "$asset" "$tmp_dir/$asset" "Tree-sitter CLI"
  gzip -dc "$tmp_dir/$asset" > "$tmp_dir/tree-sitter"
  run install -m 755 "$tmp_dir/tree-sitter" "$HOME/.local/bin/tree-sitter"
}

install_linux_nvm_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  if ! command_exists git; then
    warn "Git is not available; skipping NVM installation."
    return 0
  fi

  local version current tmp_dir
  version="$(resolve_github_version "${DOTFILES_NVM_VERSION:-}" nvm-sh/nvm "$NVM_FALLBACK_VERSION" NVM)"
  export NVM_DIR="$HOME/.nvm"

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ -e "$NVM_DIR" ]]; then
      backup_target "$NVM_DIR"
    fi

    log "Installing NVM ${version}"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf 'dry-run: git clone --branch %s --depth 1 https://github.com/nvm-sh/nvm.git %s\n' "$version" "$NVM_DIR"
    else
      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' RETURN
      if ! git clone --branch "$version" --depth 1 https://github.com/nvm-sh/nvm.git "$tmp_dir/nvm"; then
        if [[ "$version" != "$NVM_FALLBACK_VERSION" ]]; then
          warn "Could not clone NVM $version; falling back to $NVM_FALLBACK_VERSION."
          version="$NVM_FALLBACK_VERSION"
          run rm -rf "$tmp_dir/nvm"
          git clone --branch "$version" --depth 1 https://github.com/nvm-sh/nvm.git "$tmp_dir/nvm" || die "Could not install NVM."
        else
          die "Could not install NVM."
        fi
      fi
      run mv "$tmp_dir/nvm" "$NVM_DIR"
    fi
  elif [[ -d "$NVM_DIR/.git" ]]; then
    current="$(git -C "$NVM_DIR" describe --tags --exact-match 2>/dev/null || true)"
    if [[ "$current" != "$version" && -z "$(git -C "$NVM_DIR" status --porcelain)" ]]; then
      log "Updating NVM from ${current:-unknown} to $version"
      if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'dry-run: git -C %s fetch --depth 1 origin tag %s\n' "$NVM_DIR" "$version"
        printf 'dry-run: git -C %s checkout --quiet %s\n' "$NVM_DIR" "$version"
      elif git -C "$NVM_DIR" fetch --depth 1 origin tag "$version"; then
        git -C "$NVM_DIR" checkout --quiet "$version"
      else
        warn "Could not update NVM; keeping ${current:-the existing installation}."
      fi
    else
      log "NVM ${current:-installation} already available"
    fi
  else
    log "Using existing NVM installation at $NVM_DIR"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -n "$NODE_VERSION" ]]; then
      printf 'dry-run: nvm install %s and set it as default\n' "$NODE_VERSION"
    else
      printf 'dry-run: nvm install --lts and set lts/* as default\n'
    fi
    return 0
  fi

  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
  if [[ -n "$NODE_VERSION" ]]; then
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
  else
    nvm install --lts
    nvm alias default 'lts/*'
  fi
}

install_linux_tmuxinator_current() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  is_linux || return 0

  if ! command_exists gem; then
    warn "RubyGems is not available; skipping user tmuxinator install."
    return 0
  fi

  log "Installing latest tmuxinator with user RubyGems"
  run gem install --user-install tmuxinator || warn "Could not install tmuxinator with RubyGems."
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

install_wsl_browser_open() {
  is_wsl || return 0

  log "Installing WSL browser open helpers"
  run mkdir -p "$HOME/.local/bin" "$HOME/.local/bin-personal"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: install %s\n' "$HOME/.local/bin-personal/wsl-browser"
    printf 'dry-run: install %s\n' "$HOME/.local/bin/xdg-open"
    return 0
  fi

  cat > "$HOME/.local/bin-personal/wsl-browser" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "usage: wsl-browser <url>" >&2
  exit 2
fi

escaped_url="${1//\'/\'\'}"
encoded_command="$(
  printf "Start-Process -FilePath '%s'" "$escaped_url" \
    | iconv -f UTF-8 -t UTF-16LE \
    | base64 -w 0
)"
powershell.exe -NoProfile -EncodedCommand "$encoded_command" >/dev/null 2>&1
EOF
  chmod +x "$HOME/.local/bin-personal/wsl-browser"

  cat > "$HOME/.local/bin/xdg-open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -gt 0 && "$1" =~ ^https?:// ]]; then
  exec "$HOME/.local/bin-personal/wsl-browser" "$1"
fi

exec /usr/bin/xdg-open "$@"
EOF
  chmod +x "$HOME/.local/bin/xdg-open"

  local browser_name
  for browser_name in x-www-browser www-browser sensible-browser; do
    cat > "$HOME/.local/bin/$browser_name" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

exec "$HOME/.local/bin-personal/wsl-browser" "$@"
EOF
    chmod +x "$HOME/.local/bin/$browser_name"
  done
}

ensure_wsl_workspace() {
  is_wsl || return 0

  log "Preparing WSL workspace directories"
  run mkdir -p "$HOME/code" "$HOME/.local/state/scratch"

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

  run mkdir -p "$HOME/.config/tmuxinator"
  local tmuxinator_file
  for tmuxinator_file in "$DOTFILES_DIR"/tmuxinator/*.yml; do
    [[ -f "$tmuxinator_file" ]] || continue
    link_file "$tmuxinator_file" "$HOME/.config/tmuxinator/$(basename "$tmuxinator_file")"
  done
}

link_platform_tree() {
  local source_root="$1"
  [[ -d "$source_root" ]] || return 0

  local source relative
  while IFS= read -r -d '' source; do
    relative="${source#"$source_root"/}"
    link_file "$source" "$HOME/$relative"
  done < <(find "$source_root" \( -type f -o -type l \) -print0)
}

install_platform_files() {
  local platform
  platform="$(platform_name)"

  log "Applying platform configuration for $platform"
  link_platform_tree "$DOTFILES_DIR/platform/common/home"
  link_platform_tree "$DOTFILES_DIR/platform/$platform/home"
  link_platform_tree "$DOTFILES_DIR/platform/local/home"
}

install_neovim_config() {
  local target="$HOME/.config/nvim"
  if [[ -d "$target/.git" ]]; then
    log "Neovim config already cloned at $target"
    return 0
  fi

  command_exists git || die "Git is required to install the Neovim configuration."
  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  log "Cloning Neovim config branch $NVIM_CONFIG_BRANCH"
  run mkdir -p "$(dirname "$target")"
  run git clone --branch "$NVIM_CONFIG_BRANCH" "$NVIM_CONFIG_REPO" "$target"
}

bootstrap_neovim() {
  [[ "$RUN_PACKAGES" -eq 1 ]] || return 0
  if ! command_exists nvim; then
    warn "Neovim is not available; skipping plugin bootstrap."
    return 0
  fi

  log "Bootstrapping Neovim plugins and developer tools"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run nvim --headless "+Lazy! sync" +qa
    run nvim --headless "+Lazy! sync" +qa
    run nvim --headless +qa
    return 0
  fi

  local state_dir log_file first_log
  local -a nvim_cmd=(nvim)
  command_exists timeout && nvim_cmd=(timeout 900 nvim)
  state_dir="$HOME/.local/state/dotfiles"
  log_file="$state_dir/nvim-bootstrap.log"
  first_log="$state_dir/nvim-bootstrap-first-pass.log"
  run mkdir -p "$state_dir"
  : > "$log_file"

  if ! "${nvim_cmd[@]}" --headless "+Lazy! sync" +qa > "$first_log" 2>&1; then
    warn "Initial Neovim plugin sync reported an error; retrying once."
  fi
  if ! "${nvim_cmd[@]}" --headless "+Lazy! sync" +qa > "$log_file" 2>&1; then
    warn "Neovim plugin sync did not settle; see $log_file and retry with :Lazy sync."
    tail -n 40 "$log_file" >&2
    return 0
  fi
  if ! "${nvim_cmd[@]}" --headless +qa >> "$log_file" 2>&1; then
    warn "Neovim startup validation failed; see $log_file."
    tail -n 40 "$log_file" >&2
    return 0
  fi

  if grep -Eq 'Error detected|Failed to run|Package is already installing' "$log_file"; then
    warn "Neovim bootstrap completed with errors; see $log_file."
    tail -n 40 "$log_file" >&2
    return 0
  fi

  run rm -f "$first_log"
  log "Neovim plugins and developer tools are ready"
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
  log "Installing helper scripts into ~/.local/bin"
  run mkdir -p "$HOME/.local/bin"

  local script
  for script in "$DOTFILES_DIR"/scripts/*; do
    [[ -f "$script" ]] || continue
    run install -m 755 "$script" "$HOME/.local/bin/$(basename "$script")"
  done
}

install_shell_extras() {
  run mkdir -p "$HOME/.local/share"

  if [[ ! -d "$HOME/.local/share/powerlevel10k" ]] && command_exists git; then
    log "Installing Powerlevel10k"
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.local/share/powerlevel10k"
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

ensure_line_in_file() {
  local line="$1"
  local target="$2"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: ensure %q is present in %s\n' "$line" "$target"
    return 0
  fi

  touch "$target"
  grep -F "$line" "$target" >/dev/null 2>&1 || printf '\n%s\n' "$line" >> "$target"
}

ensure_linux_local_paths() {
  is_linux || return 0
  local target="$HOME/.dotfiles/.local.zsh"

  ensure_line_in_file '# Prefer user-installed Ruby gems over apt wrappers.' "$target"

  if command_exists ruby; then
    local gem_bin
    gem_bin="$(ruby -rrubygems -e 'print Gem.bindir(Gem.user_dir)' 2>/dev/null || true)"
    if [[ -n "$gem_bin" ]]; then
      ensure_line_in_file "path=(\"$gem_bin\" \$path)" "$target"
    fi
  fi
}

warn_missing_tools() {
  [[ "$DRY_RUN" -eq 0 ]] || return 0

  local missing=()
  local tool

  for tool in zsh git curl nvim tmux lazygit navi tree-sitter rg fd fzf delta node npm python3 pipx ruby gem go llm tmuxinator direnv; do
    command_exists "$tool" || missing+=("$tool")
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    warn "Missing requested tools after install: ${missing[*]}"
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
  [[ -f "$HOME/.config/nvim/init.lua" ]] || die "Neovim configuration is missing."
  if is_macos || is_wsl; then
    [[ -L "$HOME/.config/tmux/platform.conf" ]] || die "Platform tmux configuration is not linked."
  fi

  log "Done"
  printf '\nNext steps:\n'
  printf '  1. Edit ~/.gitconfig.local with this machine'\''s git identity.\n'
  printf '  2. Put secrets or work-only paths in ~/.dotfiles/.local.zsh.\n'
  printf '  3. Restart your terminal.\n'
  if [[ "$RUN_PACKAGES" -eq 1 ]]; then
    printf '  4. Open Neovim and confirm the dashboard loads.\n'
  else
    printf '  4. Start Neovim once and let its plugin/tool installation finish.\n'
  fi
  printf '  5. In tmux, press prefix + I to install plugins.\n'
  if is_wsl; then
    printf '  6. On Windows, set your terminal profile to this WSL distribution.\n'
  fi
}

main() {
  parse_args "$@"
  ensure_xcode_tools
  ensure_homebrew
  install_brew_bundle
  install_apt_packages
  install_linux_nvm_current
  install_linux_neovim_current
  install_linux_tmux_current
  install_linux_lazygit_current
  install_linux_navi_current
  install_linux_tree_sitter_current
  install_linux_cli_extras
  install_linux_tmuxinator_current
  install_linux_compat_links
  install_wsl_browser_open
  ensure_wsl_workspace
  install_dotfiles
  install_platform_files
  install_neovim_config
  bootstrap_neovim
  install_scripts
  install_shell_extras
  ensure_local_files
  ensure_linux_local_paths
  warn_missing_tools
  verify_install
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
