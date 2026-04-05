#!/usr/bin/env zsh

COLOR_INFO=""
COLOR_SUCCESS=""
COLOR_WARN=""
COLOR_ERROR=""
COLOR_RESET=""

dotfiles_init_output() {
  local start_pwd="$1"
  local log_dir log_probe run_date stdout_log stderr_log

  if [[ -t 1 ]]; then
    COLOR_INFO=$'\033[36m'
    COLOR_SUCCESS=$'\033[32m'
    COLOR_WARN=$'\033[33m'
    COLOR_ERROR=$'\033[31m'
    COLOR_RESET=$'\033[0m'
  fi

  log_dir="$start_pwd"
  log_probe="${log_dir}/.dotfiles-log-write-test.$$"

  if [[ ! -d "$log_dir" ]] || ! { : > "$log_probe"; } 2>/dev/null; then
    log_dir="$HOME"
    log_probe="${log_dir}/.dotfiles-log-write-test.$$"
    if [[ ! -d "$log_dir" ]] || ! { : > "$log_probe"; } 2>/dev/null; then
      log_dir="/tmp"
      log_probe="${log_dir}/.dotfiles-log-write-test.$$"
      if [[ ! -d "$log_dir" ]] || ! { : > "$log_probe"; } 2>/dev/null; then
        print -u2 -- "${COLOR_ERROR}[ERROR]${COLOR_RESET} ログを書き込めるディレクトリを見つけられませんでした"
        exit 1
      fi
    fi
  fi
  rm -f "$log_probe"

  run_date="$(date +%Y%m%d)"
  stdout_log="${log_dir}/dotfiles_stdout_${run_date}.log"
  stderr_log="${log_dir}/dotfiles_stderr_${run_date}.log"

  if command -v tee >/dev/null 2>&1; then
    : >> "$stdout_log"
    : >> "$stderr_log"
    exec > >(tee -a "$stdout_log") 2> >(tee -a "$stderr_log" >&2)
  else
    exec >>"$stdout_log" 2>>"$stderr_log"
  fi
}

die() { print -u2 -- "${COLOR_ERROR}[ERROR]${COLOR_RESET} $*"; exit 1; }
warn() { print -u2 -- "${COLOR_WARN}[WARNING]${COLOR_RESET} $*"; }
log() { print -- "${COLOR_INFO}[INFO]${COLOR_RESET} $*"; }
success() { print -- "${COLOR_SUCCESS}[SUCCESS]${COLOR_RESET} $*"; }

is_truthy() {
  local v="${1:-}"
  v="${v:l}"
  case "$v" in
    1|true|yes|y|on) return 0 ;;
    0|false|no|n|off|"") return 1 ;;
    *) return 1 ;;
  esac
}

ensure_value() {
  local name="$1"
  local cur
  cur="${(P)name-}"

  if [[ -n "$cur" ]]; then
    return 0
  fi
  die "$name は必須です。対話入力で指定してください"
}

ensure_sudo_non_interactive() {
  sudo -n true 2>/dev/null || die "このスクリプトは非対話実行のため sudo 権限が必要です。先に 'sudo -v' を実行してください"
}

ensure_repo_files() {
  [[ -d "$REPO_DIR" ]] || die "dotfiles ディレクトリが見つかりません: $REPO_DIR（先に公開リポジトリをクローンしてください）"
  [[ -f "$REPO_DIR/Brewfile" ]] || die "Brewfile が見つかりません: $REPO_DIR/Brewfile"
}

ensure_git_or_trigger_command_line_tools_install() {
  local install_output=""

  if command -v git >/dev/null 2>&1; then
    log "git を確認しました: $(command -v git)"
    return 0
  fi

  command -v xcode-select >/dev/null 2>&1 || die "git が見つからず、xcode-select も利用できません。Xcode Command Line Tools を手動でインストールしてください"

  log "git が見つからないため、Xcode Command Line Tools のインストーラを起動します..."
  install_output="$(xcode-select --install 2>&1 || true)"
  if [[ -n "$install_output" ]]; then
    print -- "$install_output"
  fi

  die "git が利用可能になってから、再度 ./scripts/install を実行してください"
}

homebrew_prefix() {
  print -r -- "$HOME/.homebrew"
}

homebrew_repository() {
  print -r -- "$(homebrew_prefix)/Homebrew"
}

homebrew_bin() {
  print -r -- "$(homebrew_prefix)/bin/brew"
}

install_homebrew_if_missing() {
  local brew_prefix
  local brew_repository
  local brew_bin_path
  brew_prefix="$(homebrew_prefix)"
  brew_repository="$(homebrew_repository)"
  brew_bin_path="$(homebrew_bin)"

  if [[ -x "$brew_bin_path" ]]; then
    log "既存のユーザー別 Homebrew を利用します: $brew_bin_path"
    export PATH="${brew_bin_path:h}:$PATH"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    local current_brew_prefix
    current_brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$current_brew_prefix" && "$current_brew_prefix" == "$HOME/"* ]]; then
      log "既存のユーザー別 Homebrew を利用します: $(command -v brew)"
      return 0
    fi
  fi

  ensure_git_or_trigger_command_line_tools_install

  mkdir -p "$brew_prefix/bin" || die "Homebrew 用ディレクトリを作成できませんでした: $brew_prefix"

  if [[ -e "$brew_repository" && ! -d "$brew_repository/.git" ]]; then
    die "Homebrew の配置先に想定外のファイルがあります: $brew_repository"
  fi

  if [[ ! -d "$brew_repository/.git" ]]; then
    log "ユーザー別 Homebrew を ${brew_prefix} にインストールしています..."
    git clone "https://github.com/Homebrew/brew" "$brew_repository" || die "Homebrew の clone に失敗しました: https://github.com/Homebrew/brew"
  else
    log "既存の Homebrew リポジトリを検出したため、brew コマンドを復旧します..."
  fi

  ln -sfn ../Homebrew/bin/brew "$brew_bin_path" || die "brew コマンドのリンク作成に失敗しました: $brew_bin_path"
  export PATH="${brew_bin_path:h}:$PATH"
  eval "$("$brew_bin_path" shellenv)"
  success "ユーザー別 Homebrew のセットアップが完了しました"
}

ensure_homebrew() {
  local brew_bin_path
  local brew_prefix

  brew_bin_path="$(homebrew_bin)"
  if [[ -x "$brew_bin_path" ]]; then
    export PATH="${brew_bin_path:h}:$PATH"
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
    if [[ -n "$brew_prefix" && "$brew_prefix" == "$HOME/"* ]]; then
      return 0
    fi
  fi

  die "ユーザー別 Homebrew が見つかりません。$HOME/.homebrew に Homebrew を用意してください"
}

dotfiles_install_admin_user_file() {
  print -r -- "/Users/Shared/.dotfiles_install_admin_user"
}

resolve_dotfiles_install_admin_user() {
  local admin_user_file
  local current_user
  local recorded_user=""

  admin_user_file="$(dotfiles_install_admin_user_file)"
  current_user="${USER:-$(id -un)}"

  if [[ -f "$admin_user_file" ]]; then
    IFS= read -r recorded_user < "$admin_user_file" || recorded_user=""
    recorded_user="${recorded_user//$'\r'/}"
  fi

  if [[ -z "$recorded_user" ]]; then
    if print -r -- "$current_user" > "$admin_user_file" 2>/dev/null; then
      chmod 644 "$admin_user_file" 2>/dev/null || true
      recorded_user="$current_user"
    fi
  fi

  print -r -- "$recorded_user"
}

run_stow_links() {
  local packages
  command -v stow >/dev/null 2>&1 || die "stow が見つかりません。ユーザー別 Homebrew で先にインストールしてください"

  if [[ ! -d "$STOW_DIR" ]]; then
    die "packages ディレクトリが見つかりません: $STOW_DIR"
  fi

  packages=(${STOW_DIR}/*(N:t))
  if (( ${#packages[@]} == 0 )); then
    warn "stow 対象パッケージが見つかりません: $STOW_DIR"
    return 0
  fi

  log "dotfiles のシンボリックリンクを作成しています..."
  stow -v -d "$STOW_DIR" -t "$HOME" "${packages[@]}"
  success "dotfiles のリンク作成が完了しました"
}

dotfiles_input_cache_file() {
  local cache_key="$1"
  local cache_dir="$HOME/.cache/dotfiles"

  print -r -- "${cache_dir}/${cache_key}.env"
}

load_cached_prompt_values() {
  local cache_file="$1"

  [[ -f "$cache_file" ]] || return 1
  . "$cache_file"
}

save_cached_prompt_values() {
  local cache_file="$1"
  shift

  local cache_dir="${cache_file:h}"
  local tmp_file=""
  local name=""
  local value=""

  mkdir -p "$cache_dir" 2>/dev/null || return 1
  tmp_file="$(mktemp "${cache_dir}/.${cache_file:t}.XXXXXX")" || return 1
  chmod 600 "$tmp_file" 2>/dev/null || true

  {
    print -- "# dotfiles prompt cache"
    for name in "$@"; do
      value="${(P)name-}"
      printf '%s=%q\n' "$name" "$value"
    done
  } > "$tmp_file" || {
    rm -f "$tmp_file"
    return 1
  }

  mv "$tmp_file" "$cache_file" || {
    rm -f "$tmp_file"
    return 1
  }
}

prompt_text() {
  local name="$1"
  local label="$2"
  local cur="${(P)name-}"
  local answer=""

  if [[ -n "$cur" ]]; then
    printf "%s [%s]: " "$label" "$cur"
  else
    printf "%s: " "$label"
  fi
  read -r answer
  [[ -z "$answer" ]] && answer="$cur"
  typeset -g "$name=$answer"
}

prompt_required_text() {
  local name="$1"
  local label="$2"
  local answer=""
  while true; do
    prompt_text "$name" "$label"
    answer="${(P)name-}"
    if [[ -n "$answer" ]]; then
      return 0
    fi
    warn "$label は必須です"
  done
}

prompt_yes_no() {
  local name="$1"
  local label="$2"
  local cur="${(P)name-}"
  local answer=""
  local hint="y/N"

  if is_truthy "$cur"; then
    hint="Y/n"
  fi

  while true; do
    printf "%s [%s]: " "$label" "$hint"
    read -r answer
    if [[ -z "$answer" ]]; then
      if is_truthy "$cur"; then
        typeset -g "$name=1"
      else
        typeset -g "$name=0"
      fi
      return 0
    fi

    case "${answer:l}" in
      y|yes)
        typeset -g "$name=1"
        return 0
        ;;
      n|no)
        typeset -g "$name=0"
        return 0
        ;;
      *)
        warn "y か n を入力してください"
        ;;
    esac
  done
}

prompt_reuse_cached_values() {
  local cache_file="$1"
  local label="${2:-前回の入力値}"
  local reuse_cache_confirm="0"

  [[ -f "$cache_file" ]] || return 1

  prompt_yes_no reuse_cache_confirm "${label} を再利用する"
  if ! is_truthy "$reuse_cache_confirm"; then
    return 1
  fi

  if load_cached_prompt_values "$cache_file"; then
    success "${label} を再利用します"
    return 0
  fi

  warn "${label} の読み込みに失敗したため、再入力してください"
  return 1
}

confirm_execution() {
  local answer=""
  while true; do
    printf "この内容で実行しますか？ [y/N]: "
    read -r answer
    case "${answer:l}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) warn "y か n を入力してください" ;;
    esac
  done
}
