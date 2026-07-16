# Dotfiles

Small Unix-shaped dotfiles for bootstrapping a laptop without a clever framework
getting in the way. macOS is still the primary polished path; Windows support is
WSL-first so the development environment stays close to the Mac workflow.

## Fresh Laptop

### macOS

Manual setup:

```bash
xcode-select --install
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

One-liner setup:

```bash
curl -fsSL https://raw.githubusercontent.com/chris-a-phillips/dotfiles/main/quick-setup.sh | bash
```

The one-liner uses the `main` branch by default. Override it with
`DOTFILES_BRANCH=develop` if you want to test that branch.

### Windows / WSL

Use Windows for the laptop, terminal host, window management, and corporate apps.
Use WSL Ubuntu for development:

```text
Windows 11
  Windows Terminal
    WSL Ubuntu
      zsh + tmux + nvim + lazygit + navi + helper scripts
```

On Windows, install WSL from an elevated PowerShell prompt if it is allowed:

```powershell
wsl --install -d Ubuntu
```

After Ubuntu starts and your Linux user is created, clone and install inside WSL:

```bash
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The Windows host helper is intentionally policy-aware and dry by default:

```powershell
powershell -File .\windows\setup-host.ps1
powershell -File .\windows\setup-host.ps1 -InstallRecommended
powershell -File .\windows\setup-host.ps1 -ExportWinget
```

`-InstallRecommended` installs Windows Terminal and PowerToys when `winget` is
available and policy allows it. PowerToys is the Windows comfort layer for
FancyZones window layouts, Keyboard Manager remaps, Command Palette launching,
Peek previews, and Text Extractor OCR.

`-ExportWinget` writes a host app manifest to `windows/winget-packages.json`.
That file can be used later with `winget import`, but review it before using it
on a managed work laptop.

Inside WSL, keep active repos under the Linux filesystem:

```bash
~/code
```

Avoid `/mnt/c/...` for Linux-heavy development unless company tooling requires
it. The installer creates `~/code` and `~/scratch` inside WSL.

Dev Drive can be useful for Windows-native repos and package caches, but it
needs Windows policy/admin support. Prefer WSL `~/code` for this setup first.

## What Install Does

- Installs Xcode Command Line Tools on macOS if needed.
- Installs Homebrew on macOS if needed.
- Runs `brew bundle --file Brewfile` on macOS.
- Installs apt-based core development packages on Ubuntu/Debian/WSL when possible.
- Resolves the latest Neovim, tmux, LazyGit, Navi, and Tree-sitter CLI releases on Linux and falls back to known-good versions when needed.
- Installs or updates NVM and installs the latest Node.js LTS release on Linux.
- Clones the separate Neovim configuration repository into `~/.config/nvim`.
- Bootstraps current Neovim plugins and Mason-managed developer tools during a full install.
- Symlinks shell, git, tmux, Ghostty, LazyGit, and Navi config.
- Applies common, macOS, Linux, or WSL-specific files from `platform/`.
- Copies helper scripts into `~/.local/bin`.
- Installs Powerlevel10k and tmux plugin manager.
- Creates local-only files for machine-specific settings and platform git config.

Existing files are moved into `~/.dotfiles-backup/<timestamp>/` before links are created.

## Useful Flags

```bash
./install.sh --no-brew
./install.sh --no-packages
./install.sh --dry-run
./install.sh --help
```

`--no-packages` skips package and runtime installation, but still links the
configuration and clones the Neovim repository.

## Release Selection

On Linux, the installer asks each upstream GitHub project for its latest release.
If that lookup or download fails, it retries with a known-good release.

Known-good fallbacks are Neovim v0.12.3, tmux 3.6b, LazyGit v0.62.2,
Navi v2.24.0, Tree-sitter CLI v0.25.10, and NVM v0.40.3.

Set `DOTFILES_NEOVIM_VERSION`, `DOTFILES_TMUX_VERSION`,
`DOTFILES_LAZYGIT_VERSION`, `DOTFILES_NAVI_VERSION`,
`DOTFILES_TREE_SITTER_VERSION`, `DOTFILES_NVM_VERSION`, or `DOTFILES_NODE_VERSION`
to request a specific version.

## Local Files

Keep secrets, work-only paths, and machine identity out of git.

Shell exports go here:

```bash
~/.dotfiles/.local.zsh
```

Git identity goes here:

```bash
~/.gitconfig.local
```

Platform-specific Git credential helper settings go here:

```bash
~/.gitconfig.platform
```

Platform-specific files use a mirrored home-directory layout:

```text
platform/common/home/   # every platform
platform/macos/home/    # macOS
platform/linux/home/    # native Linux
platform/wsl/home/      # WSL
platform/local/home/    # ignored machine-local overrides
```

For example, `platform/wsl/home/.config/tmux/platform.conf` becomes
`~/.config/tmux/platform.conf` on WSL. See
[`platform/README.md`](platform/README.md).

The Neovim config is cloned separately from
`https://github.com/chris-a-phillips/lazyvim.git`. Override the repository or
branch with `DOTFILES_NVIM_REPO` and `DOTFILES_NVIM_BRANCH`.

`lazy-lock.json` and `lazyvim.json` remain ignored so a fresh setup resolves
current plugin versions rather than preserving a laptop-specific snapshot.
A full install bootstraps Lazy and Mason automatically. When using
`--no-packages`, let the first Neovim launch finish installing plugins and
developer tools before exiting.

Navi config is managed at:

```bash
~/.config/navi/config.yaml
```

Example:

```gitconfig
[user]
	name = Chris Phillips
	email = you@example.com
```

## Repo Layout

- [install.sh](install.sh): main bootstrap script
- [quick-setup.sh](quick-setup.sh): clone/update wrapper for a fresh Mac
- [Brewfile](Brewfile): Homebrew packages and casks
- [.zshrc](.zshrc): shell setup
- [.aliases](.aliases): aliases
- [.gitconfig](.gitconfig): shared git defaults
- [tmux/](tmux): tmux config
- [platform/](platform): common and operating-system-specific home-directory overlays
- [configs/ghostty/config.ghostty](configs/ghostty/config.ghostty): Ghostty config
- [configs/lazygit/config.yaml](configs/lazygit/config.yaml): shared LazyGit config
- [configs/navi/](configs/navi): Navi config and local cheatsheets
- [scripts/](scripts): helper scripts copied to `~/.local/bin`
- [windows/setup-host.ps1](windows/setup-host.ps1): optional Windows host helper

## After Install

Restart the terminal, then check:

```bash
command -v gst gsw gbnew greset help mkcd pull-all
tmux -V
nvim --version
node --version
npm --version
```

In tmux, press `prefix + I` to install plugins. Tmux Continuum autosaves the
tmux environment every 15 minutes and restores the last save when a new tmux
server starts.

## Security Notes

Do not commit API keys, app licenses, SSH keys, or work credentials. If one ever lands in git history, rotate it even after removing it from the current files.
