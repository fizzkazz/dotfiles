_dotfiles_homebrew_prefix="$HOME/.homebrew"

if [ -x "${_dotfiles_homebrew_prefix}/bin/brew" ]; then
  export PATH="${_dotfiles_homebrew_prefix}/bin:${_dotfiles_homebrew_prefix}/sbin:$PATH"
fi

# mise
eval "$(mise activate zsh)"

# starship
eval "$(starship init zsh)"

# zsh-autosuggestions (official Homebrew install docs: source from $(brew --prefix) path)
if command -v brew >/dev/null 2>&1; then
  _dotfiles_brew_prefix="$(brew --prefix)"
  if [ -r "${_dotfiles_brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "${_dotfiles_brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
  unset _dotfiles_brew_prefix
fi

unset _dotfiles_homebrew_prefix

. "$HOME/.local/bin/env"

# clux: open claude code (left 1/3) + nvim (right 2/3) in tmux
clux() {
  local force=0
  local dir="."

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c) force=1; shift ;;
      *) dir="$1"; shift ;;
    esac
  done

  # sanitize session name (tmux replaces leading dots with underscores)
  local session="clux-$(basename "$(realpath "$dir")" | tr '.' '_')"

  if tmux has-session -t "$session" 2>/dev/null; then
    if [[ $force -eq 1 ]]; then
      tmux kill-session -t "$session"
    else
      tmux attach-session -t "$session"
      return
    fi
  fi

  tmux new-session -d -s "$session" -c "$dir"
  tmux send-keys -t "${session}:0.0" "claude" Enter
  local win_width
  win_width=$(tmux display-message -t "${session}:0" -p '#{window_width}' 2>/dev/null || echo 220)
  tmux split-window -h -l $(( win_width * 2 / 3 )) -t "${session}:0.0" -c "$dir"
  tmux send-keys -t "${session}:0.1" "nvim ." Enter
  tmux select-pane -t "${session}:0.0"
  tmux attach-session -t "$session"
}
