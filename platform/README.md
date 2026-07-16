# Platform overlays

The installer links files from these trees into the same relative path under
`$HOME`:

- `common/home/`: every supported platform
- `macos/home/`: macOS only
- `linux/home/`: native Linux only
- `wsl/home/`: Windows Subsystem for Linux only
- `local/home/`: machine-local overrides applied last

For example:

```text
platform/wsl/home/.config/tmux/platform.conf
```

is linked to:

```text
~/.config/tmux/platform.conf
```

Keep portable platform behavior in the tracked directories. `platform/local/`
is gitignored and is suitable for machine-only files, but secrets should
normally stay in `~/.dotfiles/.local.zsh` or another dedicated secret store.
