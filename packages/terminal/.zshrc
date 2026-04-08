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
