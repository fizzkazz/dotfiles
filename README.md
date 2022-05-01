# dotfiles

A bundle of configuration files and executable shell script helps you to set up MacOS. (Windows/Linux is NOT supported.)

## Usage of the shell script

```bash
xcode-select --install # If you have not installed Xcode or Xcode Command Line Tools
curl -H "Cache-Control: no-cache" https://github.com/fizzkazz/dotfiles/raw/master/packages/cli/scripts/dotfiles > "$HOME"/dotfiles.sh
sh "$HOME"/dotfiles.sh
```
