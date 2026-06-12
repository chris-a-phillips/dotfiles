# Capture the previous command's tmux pane output for the `vlogs` helper.
# Disable with: export VLOGS_DISABLE=1

_dotfiles_vlogs_capture() {
  [[ "${VLOGS_DISABLE:-0}" == "1" ]] && return 0

  if command -v vlogs-capture >/dev/null 2>&1; then
    vlogs-capture "$@" >/dev/null 2>&1
  elif [[ -x "$HOME/.dotfiles/scripts/vlogs-capture" ]]; then
    "$HOME/.dotfiles/scripts/vlogs-capture" "$@" >/dev/null 2>&1
  fi
}

_dotfiles_vlogs_preexec() {
  _dotfiles_vlogs_capture start "$1"
}

_dotfiles_vlogs_precmd() {
  local exit_status=$?
  _dotfiles_vlogs_capture finish "$exit_status"
  return "$exit_status"
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _dotfiles_vlogs_preexec
add-zsh-hook precmd _dotfiles_vlogs_precmd
