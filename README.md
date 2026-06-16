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
- Symlinks shell, git, tmux, Ghostty, LazyGit, and Navi config.
- Copies helper scripts into `~/bin`.
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
- [configs/ghostty/config.ghostty](configs/ghostty/config.ghostty): Ghostty config
- [configs/lazygit/config.yaml](configs/lazygit/config.yaml): shared LazyGit config
- [configs/navi/](configs/navi): Navi config and local cheatsheets
- [scripts/](scripts): helper scripts copied to `~/bin`
- [windows/setup-host.ps1](windows/setup-host.ps1): optional Windows host helper

## After Install

Restart the terminal, then check:

```bash
command -v gst gsw gbnew greset help mkcd pull-all
tmux -V
nvim --version
```

In tmux, press `prefix + I` to install plugins. Tmux Continuum autosaves the
tmux environment every 15 minutes and restores the last save when a new tmux
server starts.

## Security Notes

Do not commit API keys, app licenses, SSH keys, or work credentials. If one ever lands in git history, rotate it even after removing it from the current files.
