# dotfiles

A bundle of configuration files and executable shell script helps you to set up M1/M2 MacOS.

## Usage of the shell script

```bash
xcode-select --install
sudo xcodebuild -license accept
softwareupdate --install-rosetta --agree-to-license
curl -H "Cache-Control: no-cache" https://raw.githubusercontent.com/fizzkazz/dotfiles/master/scripts/dotfiles > "$HOME"/dotfiles.sh
sh "$HOME"/dotfiles.sh
```
