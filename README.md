# Dotfiles

Small macOS-first dotfiles for bootstrapping a new laptop without a clever framework getting in the way.

## Fresh Laptop

Manual setup:

```bash
xcode-select --install
git clone https://github.com/chris-a-phillips/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

One-liner setup:

```bash
curl -fsSL https://raw.githubusercontent.com/chris-a-phillips/dotfiles/develop/quick-setup.sh | bash
```

The one-liner uses the `develop` branch by default. Override it with `DOTFILES_BRANCH=main` if you later move the stable setup there.

## What Install Does

- Installs Xcode Command Line Tools if needed.
- Installs Homebrew if needed.
- Runs `brew bundle --file Brewfile`.
- Symlinks shell, git, tmux, Ghostty, LazyGit, and Navi config.
- Copies helper scripts into `~/bin`.
- Installs Powerlevel10k and tmux plugin manager.
- Creates local-only files for machine-specific settings.

Existing files are moved into `~/.dotfiles-backup/<timestamp>/` before links are created.

## Useful Flags

```bash
./install.sh --no-brew
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
- [Brewfile](Brewfile): Homebrew packages, casks, and VS Code extensions
- [.zshrc](.zshrc): shell setup
- [.aliases](.aliases): aliases
- [.gitconfig](.gitconfig): shared git defaults
- [tmux/](tmux): tmux config
- [configs/ghostty/config.ghostty](configs/ghostty/config.ghostty): Ghostty config
- [configs/lazygit/config.yaml](configs/lazygit/config.yaml): shared LazyGit config
- [configs/navi/](configs/navi): Navi config and local cheatsheets
- [scripts/](scripts): helper scripts copied to `~/bin`

## After Install

Restart the terminal, then check:

```bash
command -v gst gsw gbnew greset help mkcd backup pull-all
tmux -V
nvim --version
```

In tmux, press `prefix + I` to install plugins.

## Security Notes

Do not commit API keys, app licenses, SSH keys, or work credentials. If one ever lands in git history, rotate it even after removing it from the current files.
