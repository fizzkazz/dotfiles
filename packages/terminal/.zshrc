export PATH=$PATH:$HOME/scripts
export GIT_CLONE_PATH="$HOME"/src/fizzkazz
export PATH="$HOME/homebrew/bin:$PATH"
export CHROME_EXECUTABLE="$HOME"/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome

eval "$(starship init zsh)"

# Aliases
alias cat="bat"
alias ll="ls -lah --git"
alias lt="ll -TL 3 --ignore-glob=.git"
alias pr="gh pr view --web"
alias fd="fd -H"

# Docker aliases
alias dps="docker ps"
alias dpa="docker ps -a"
alias di="docker images"
alias dex="docker exec -i -t"
dstop() { docker stop $(docker ps -a -q); }
drm() { docker rm $(docker ps -a -q); }
alias drmf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'
drmi() { docker rmi $(docker images -q); }
alias dsp="docker system prune --all"

# Docker compose aliases
alias dcu="docker comopse up"
alias dcd="docker compose down"
dcr() { docker compose run $@ }

# Zsh auto suggestion
. $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# asdf
. $(brew --prefix asdf)/libexec/asdf.sh

# Set JAVA_HOME
. "$HOME"/.asdf/plugins/java/set-java-home.zsh

# Google Cloud SDK
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
