#!/usr/bin/env bash

set -euo pipefail

CONTAINER_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f /.dockerenv ]]; then
  printf 'error: install-container.sh must run inside a container.\n' >&2
  exit 1
fi

# Tree-sitter 0.27 release binaries require a newer glibc than the shared
# Debian 12 image. Keep the container on the newest verified compatible build.
DOTFILES_TREE_SITTER_VERSION="${DOTFILES_TREE_SITTER_VERSION:-v0.25.10}"

# Reuse logging, command detection, linking, and backup functions without
# running install.sh's main workstation installation.
# shellcheck source=install.sh
source "$CONTAINER_DOTFILES_DIR/install.sh"

RUN_BREW=0
RUN_PACKAGES=0
DELTA_FALLBACK_VERSION="${DOTFILES_DELTA_FALLBACK_VERSION:-0.19.2}"

OPTIONAL_STEP_SUCCEEDED=1

run_optional_step() {
  local description="$1"
  shift

  local status

  # Run optional customization in an isolated shell. A failure must not make
  # Dev Containers consider the shared environment unusable.
  set +e
  (
    set -e
    "$@"
  )
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    OPTIONAL_STEP_SUCCEEDED=1
    return 0
  fi

  OPTIONAL_STEP_SUCCEEDED=0
  warn "$description failed."
  warn "The shared development container is still ready to use."
  return 0
}

install_container_packages() {
  local packages=()

  command_exists fd || packages+=(fd-find)
  command_exists fzf || packages+=(fzf)
  command_exists lsof || packages+=(lsof)
  command_exists rg || packages+=(ripgrep)
  command_exists tmux || packages+=(tmux)
  command_exists tree || packages+=(tree)

  if [[ "${#packages[@]}" -eq 0 ]]; then
    log "Container terminal packages are already installed"
    return 0
  fi

  command_exists apt-get ||
    die "This container does not provide apt-get."

  log "Installing personal terminal packages"
  run_as_root apt-get update
  run_as_root apt-get install -y "${packages[@]}"

  # Ubuntu names the fd executable fdfind. The existing helper creates the
  # expected ~/.local/bin/fd link.
  install_linux_compat_links
}

install_container_delta() {
  if command_exists delta; then
    log "Using existing $(delta --version | head -n 1)"
    return 0
  fi

  local architecture
  local target
  local version
  local archive
  local fallback_archive
  local temporary_directory

  architecture="$(linux_release_arch)" ||
    die "Delta is not available for this container architecture."

  case "$architecture" in
  x86_64)
    target="x86_64-unknown-linux-gnu"
    ;;
  arm64)
    target="aarch64-unknown-linux-gnu"
    ;;
  *)
    die "Unsupported Delta architecture: $architecture"
    ;;
  esac

  version="$(
    resolve_github_version \
      "${DOTFILES_DELTA_VERSION:-}" \
      dandavison/delta \
      "$DELTA_FALLBACK_VERSION" \
      Delta
  )"

  archive="delta-${version}-${target}.tar.gz"
  fallback_archive="delta-${DELTA_FALLBACK_VERSION}-${target}.tar.gz"
  temporary_directory="$(mktemp -d)"
  trap 'rm -rf "$temporary_directory"' RETURN

  log "Installing Delta ${version} into ~/.local/bin"
  run mkdir -p "$HOME/.local/bin"

  download_github_release_asset \
    dandavison/delta \
    "$version" \
    "$archive" \
    "$DELTA_FALLBACK_VERSION" \
    "$fallback_archive" \
    "$temporary_directory/$archive" \
    Delta

  version="$DOWNLOADED_VERSION"

  run tar -xzf "$temporary_directory/$archive" \
    -C "$temporary_directory"

  run install -m 0755 \
    "$temporary_directory/delta-${version}-${target}/delta" \
    "$HOME/.local/bin/delta"

  run rm -rf "$temporary_directory"
  trap - RETURN
}


install_container_user_tool() {
  local installer="$1"
  local status

  # Existing installers use RUN_PACKAGES as their opt-in guard. This enables
  # only the selected installer, not install.sh's full workstation setup.
  RUN_PACKAGES=1

  # Their RETURN cleanup traps otherwise remain active until this wrapper
  # returns, after the installer's local tmp_dir variable is out of scope.
  set +e
  "$installer"
  status=$?
  trap - RETURN
  set -e

  return "$status"
}

install_container_configuration() {
  log "Linking personal container configuration"

  # The personal Git config rewrites GitHub HTTPS URLs to SSH. Bootstrap the
  # public config repositories without requiring SSH keys or known_hosts.
  export GIT_CONFIG_GLOBAL=/dev/null

  run_optional_step "Dotfile linking" install_dotfiles
  run_optional_step "Platform configuration" install_platform_files
  run_optional_step "Neovim configuration" install_neovim_config
  run_optional_step "Personal script linking" install_scripts
  run_optional_step "Shell extras" install_shell_extras
  run_optional_step "Local file creation" ensure_local_files
  run_optional_step "Local path creation" ensure_linux_local_paths
}

main() {
  local configuration_ready=1

  log "Preparing personal development-container configuration"

  run_optional_step \
    "Terminal package installation" \
    install_container_packages

  run_optional_step \
    "Delta installation" \
    install_container_delta
  if [[ "$OPTIONAL_STEP_SUCCEEDED" -eq 0 ]]; then
    configuration_ready=0
  fi

  run_optional_step \
    "Neovim installation" \
    install_container_user_tool \
    install_linux_neovim_current
  if [[ "$OPTIONAL_STEP_SUCCEEDED" -eq 0 ]]; then
    configuration_ready=0
  fi

  run_optional_step \
    "LazyGit installation" \
    install_container_user_tool \
    install_linux_lazygit_current

  run_optional_step \
    "Navi installation" \
    install_container_user_tool \
    install_linux_navi_current

  run_optional_step \
    "Tree-sitter installation" \
    install_container_user_tool \
    install_linux_tree_sitter_current

  if [[ "$configuration_ready" -eq 1 ]]; then
    run_optional_step \
      "Personal configuration linking" \
      install_container_configuration
  else
    warn "Skipping personal configuration links because Neovim or Delta is unavailable."
  fi

  log "Shared development-container tooling remains ready"
}

main "$@"
