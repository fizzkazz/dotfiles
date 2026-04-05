_dotfiles_homebrew_prefix="$HOME/.homebrew"

if [ -x "${_dotfiles_homebrew_prefix}/bin/brew" ]; then
  export PATH="${_dotfiles_homebrew_prefix}/bin:${_dotfiles_homebrew_prefix}/sbin:$PATH"
fi

# Upstream recommends sourcing zsh-autocomplete near the top of .zshrc.
if [ -r "${_dotfiles_homebrew_prefix}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
  source "${_dotfiles_homebrew_prefix}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
fi

unset _dotfiles_homebrew_prefix

# mise
eval "$(mise activate zsh)"

# starship
eval "$(starship init zsh)"
