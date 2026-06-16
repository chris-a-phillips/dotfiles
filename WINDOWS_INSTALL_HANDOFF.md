# Windows Setup Context Brief

This note is meant to give a future chat awareness of the user's environment before it starts changing the install scripts. It is not a rigid implementation plan. Treat it as a map of preferences, recent decisions, and places where a quick repo scan may miss important context.

## Big Picture

The user is probably getting a Windows work laptop, likely a Lenovo ThinkPad. They have not used Windows professionally in a long time, but the transition should not be treated as a total rebuild of their workflow.

Their setup is terminal-first and Unix-shaped. The closest Windows equivalent is probably:

```text
Windows 11 for the laptop/app/window-management layer
WSL Ubuntu for the real development environment
```

The important distinction is that Windows should not become the place where all Unix tools are forced to run natively. The user's development workflow belongs inside WSL: `zsh`, `tmux`, Neovim, repos, helper scripts, `navi`, `lazygit`, `llm`, and project tooling.

Windows itself is mostly there for:

- Windows Terminal
- PowerToys/FancyZones
- keyboard/window behavior
- phone integration
- launcher behavior, probably Raycast or PowerToys Run
- corporate apps and work-device management

The user cares more about preserving the feel of the workflow than making every tool identical across platforms.

## Personal Workflow Shape

The daily loop is:

- open a terminal
- live inside `tmux`
- use Neovim heavily
- use `navi` for remembered commands
- use `lazygit`
- use helper scripts from `~/bin`
- use `tmuxinator` for repeatable workspaces
- keep project repos under a predictable `~/code`-style folder

The work environment should feel like:

```text
Windows Terminal
  WSL Ubuntu
    zsh
    tmux
      nvim
      lazygit
      llm chat
      project shells
```

Do not assume the user wants a VS Code-centered setup. VS Code may exist for work, but it is not the core of this dotfiles conversation.

## Repository Boundaries

The dotfiles repo is:

```text
~/.dotfiles
```

The Neovim config is intentionally its own separate repo:

```text
~/.config/nvim
```

That separation matters. Do not fold Neovim into dotfiles unless the user explicitly changes their mind.

The Obsidian vault/repo is elsewhere:

```text
/Users/esquire/Documents/second_brain
```

Most code repos live under:

```text
/Users/esquire/code
```

On Windows/WSL, the comparable place should probably be:

```text
~/code
```

Avoid putting active repos under `/mnt/c/...` unless company policy or tooling forces that.

## Current Install Script Awareness

`install.sh` is currently a macOS-oriented Bash installer. It is fairly clean and should not be casually rewritten from scratch.

It already has useful behavior worth preserving:

- `--dry-run`
- `--no-brew`
- backup of existing files before symlinking
- rerunnable symlink logic
- creation of local-only files
- installation of helper scripts into `~/bin`
- linking all tmuxinator configs from the repo

It currently assumes macOS for package automation. On non-macOS it warns and skips Homebrew.

If Windows support is added, the likely shape is a platform-aware flow rather than one giant script that tries to do everything everywhere.

The natural split is:

- macOS host setup stays mostly as-is
- Windows host setup probably lives in PowerShell and uses `winget`
- WSL setup stays Bash and handles the Unix dev environment

This does not need to become overengineered immediately. A small clean split is better than a grand installer framework.

## Shell Environment Notes

`.zshrc` is intentionally slim now.

Important current assumptions:

```sh
export PATH="$HOME/bin:/usr/local/bin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"
export EDITOR=nvim
export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
```

It loads `direnv` if available:

```sh
eval "$(direnv hook zsh)"
```

It sources:

```text
~/.dotfiles/.aliases
~/.dotfiles/.local.zsh
~/.p10k.zsh
```

For WSL, the PATH line deserves attention. `/opt/homebrew/bin` is a macOS Apple Silicon assumption. If Linuxbrew is used, `/home/linuxbrew/.linuxbrew/bin` may matter. If apt/manual installs are used, Linuxbrew may not be needed at all.

Secrets, corporate paths, and machine-specific exports should stay in:

```text
~/.dotfiles/.local.zsh
```

## Package Awareness

The `Brewfile` is not a Windows package list. It is a statement of the user's current tool ecosystem.

Current core CLI/tooling:

- `git`
- `git-delta`
- `lazygit`
- `llm`
- `navi`
- `neovim`
- `tmux`
- `tmuxinator`
- `direnv`
- `ripgrep`
- `fd`
- `fzf`
- `eza`
- `tree`
- `tldr`
- `node`
- `nvm`
- `python`
- `pyenv`
- `pipenv`
- `virtualenv`
- `mongosh`
- `postgresql`
- `mongodb-community`

Current Mac-only or Mac-skewed app layer:

- `ghostty`
- `alt-tab`
- `hiddenbar`
- `itsycal`
- `font-hack-nerd-font`

On a work Windows laptop, MongoDB/Postgres/Docker-style services may be policy-sensitive. Treat those as optional or confirm before automating.

For Windows host apps, `winget` is the likely direction, but package IDs should be verified on the actual machine rather than guessed and hardcoded.

## Terminal And Window Management

Ghostty is the Mac terminal. Alacritty was intentionally removed.

Ghostty config lives at:

```text
configs/ghostty/config.ghostty
```

Current notable Ghostty preferences:

```ini
background = #000000
background-opacity = 0.8
font-feature = -calt, -liga, -dlig
```

The `font-feature` line disables programming ligatures so operators like `!==`, `===`, and `>=` render plainly.

For Windows, do not assume Ghostty. The more realistic default is Windows Terminal with WSL as the default profile.

PowerToys matters because the user likes Rectangle-like window movement on macOS. FancyZones is probably the Windows equivalent to pay attention to.

Potential Windows host tools:

- Windows Terminal
- PowerToys
- FancyZones
- Keyboard Manager
- PowerToys Run
- Raycast for Windows, if allowed and stable enough
- Phone Link
- iCloud for Windows only if corporate policy and privacy make sense

## Navi

Navi location has been a pain point. The user specifically wants it stable under:

```text
~/.config/navi
```

Dotfiles link:

```text
configs/navi/config.yaml -> ~/.config/navi/config.yaml
configs/navi/cheats -> ~/.config/navi/cheats
```

Do not move Navi to a platform-specific application directory or random default location.

Navi cheats include script launchers and tmuxinator helpers. The user expects `navi` with no arguments to show both custom helper scripts and the git/bash scripts that were moved into navi.

## Tmux And Tmuxinator

Tmux is central to the workflow.

Be careful with tmux styling. There was a lot of iteration, and some styling experiments were rejected. The user currently cares about:

- readable borders
- obvious active pane/window
- not overloading the statusline with useless widgets
- keeping tmux useful rather than decorative

Tmuxinator configs live in:

```text
tmuxinator/*.yml
```

They should be symlinked into:

```text
~/.config/tmuxinator
```

A stale live `~/.config/tmuxinator/dev.yml` once caused confusing behavior because it was not linked to the repo. Be alert for live config drift.

Recent helper scripts:

```text
scripts/tmux-lazygit
scripts/tmux-repo
```

`tmux-lazygit` avoids lazygit getting stuck outside a repo.

`tmux-repo` starts the generic repo workspace from a chosen repo:

```sh
tmux-repo
tmux-repo ~/code/x-in-y
tmux-repo /path/to/repo
```

LLM tmuxinator panes use this system prompt:

```sh
llm chat --system "Respond with brief answers unless explicitly told otherwise"
```

That is intentional. It makes the chat pane default to brief responses.

## Neovim Context

Neovim is a separate repo, but the Windows/WSL setup needs to support it.

Current Neovim shape:

- LazyVim
- Snacks dashboard/explorer/picker
- Trouble
- Lualine
- Mason
- Treesitter context
- Screenkey
- Navi launcher
- `scrollEOF`
- Catppuccin/Lush color work
- transparent terminal plus dark/black Neovim background preferences
- tmux/neovim navigation integration

Important LSP choices:

- Python uses Pyright plus Ruff.
- TypeScript uses `ts_ls`.
- `vtsls` was removed/disabled.
- Emmet uses `emmet_language_server`.
- `emmet_ls` was removed/disabled.

Recent Neovim behavior preferences:

- Snacks explorer reveal-current-file is the default behavior.
- `<leader>e` toggles explorer open/closed.
- Search should use repo root:
  - `<leader>/`
  - `<leader><space>`
- Buffer picker is `<leader>,`.
- The user likes native `V` for linewise visual selection and chose not to add `vv`.
- Useful mappings added:
  - `=ap` paragraph format
  - `<leader>p` paste without yanking replaced text
  - `<leader>d` delete without yanking
  - `Q` noop
- WhichKey should be helpful but fast. Do not make it slow or intrusive again.
- Macro recording is visible in lualine.
- Trouble diagnostics should follow the current line in the editing window.

For WSL, a future setup needs Neovim dependencies to be available inside WSL, not only on the Windows host.

## Git Identity Awareness

The user's personal Git identity is:

```text
Chris Phillips <phillipsachris@gmail.com>
```

This was important because multiple repo histories were repaired.

For a corporate Windows laptop, do not blindly hardcode the personal email into all work repos. The current installer creates:

```text
~/.gitconfig.local
```

That is the right place to let machine-specific identity live.

Keep history rewriting out of scope unless explicitly requested.

## Windows Host Awareness

The likely Windows host setup should be thought of as comfort and integration, not the dev runtime.

Areas to consider:

- Windows Terminal default profile should probably be WSL Ubuntu.
- PowerToys/FancyZones should approximate Rectangle.
- Keyboard Manager may help with Mac-to-Windows muscle memory.
- Raycast for Windows is relevant, but it may be beta/policy-sensitive.
- Phone Link can help with phone integration.
- iCloud for Windows can help with Apple ecosystem continuity, but it may be inappropriate on a managed corporate laptop.
- Windows clipboard history and Snipping Tool may replace some Mac utilities.
- QuickLook-style preview could be useful, but should be policy-aware.

Ask before installing personal cloud/password/photo syncing tools on a work machine.

## WSL Awareness

Inside WSL, the setup should feel like a normal Linux dev machine.

Potential WSL packages/tools:

- `zsh`
- `git`
- `curl`
- `build-essential`
- `ripgrep`
- `fd-find`
- `fzf`
- `eza`
- `tmux`
- `neovim`
- `direnv`
- `python3`
- `python3-venv`
- `python3-pip`
- `nvm`
- `lazygit`
- `navi`
- `llm`
- `tmuxinator`
- Powerlevel10k
- TPM

The unsettled question is package source:

- apt for stable basics
- GitHub releases for newer CLI tools
- Linuxbrew for Brewfile parity
- language-specific installers for Node/Python tooling

Do not assume one answer without considering corporate network restrictions.

## Things Another Chat Might Miss

- Dotfiles changes may be dirty already. Check `git status --short`.
- Neovim changes may be in a different repo and dirty too.
- Some live configs may be symlinks and some may be stale files.
- `~/bin` matters because scripts are installed there.
- `~/.local/bin` also matters.
- The user dislikes unrelated code being placed in the wrong config file.
- The user prefers changes to follow existing repo style.
- The user likes one-file plugin visibility in Neovim, but still wants enable/disable tables for clarity.
- The user does not want unnecessary statusline/dashboard clutter.
- The user cares about fast keyboard response more than elaborate hints.
- Control keys are reserved mostly for navigation/tmux habits.
- Option/Alt can be used when needed, but word navigation matters more than custom resizing.
- Do not revive old Alacritty references.
- Do not move Navi.
- Do not assume Ghostty on Windows.

## Useful References

These are context references, not a mandate to implement everything from them:

- WSL install: https://learn.microsoft.com/en-us/windows/wsl/install
- WSL basic commands: https://learn.microsoft.com/en-us/windows/wsl/basic-commands
- Windows Terminal: https://learn.microsoft.com/en-us/windows/terminal/install
- PowerToys: https://learn.microsoft.com/en-us/windows/powertoys/
- FancyZones: https://learn.microsoft.com/en-us/windows/powertoys/fancyzones
- WinGet: https://learn.microsoft.com/en-us/windows/package-manager/winget/
- Phone Link: https://support.microsoft.com/en-us/topic/phone-link-requirements-and-setup-cd2a1ee7-75a7-66a6-9d4e-bf22e735f9e3
- iCloud for Windows: https://support.apple.com/guide/icloud-windows/welcome/icloud
- Raycast for Windows: https://www.raycast.com/windows

## Good First Questions For A Future Chat

Before making a Windows installer too specific, clarify what the work laptop allows:

- Is WSL 2 allowed?
- Is `winget` allowed?
- Is the Microsoft Store available?
- Is PowerToys allowed?
- Is Raycast allowed?
- Is Docker Desktop allowed?
- Are GitHub downloads allowed from WSL?
- Does work require code under Windows storage, or can repos live in WSL?
- Should Git identity use work email or personal email on the work machine?

The safest first implementation is probably modest:

- preserve macOS behavior
- detect WSL
- add WSL package/bootstrap support
- keep symlink behavior
- add a separate Windows PowerShell script for host apps
- document any manual steps that are likely to be blocked by corporate policy

