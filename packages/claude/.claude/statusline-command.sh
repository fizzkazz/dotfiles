#!/bin/bash
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

# Truncate directory like Starship (home → ~, show up to 3 components)
dir=$(echo "$cwd" | sed "s|^$HOME|~|")
truncated=$(echo "$dir" | awk -F'/' '{
  if (NF <= 4) { print $0 }
  else { print $1 "/…/" $(NF-1) "/" $NF }
}')

# Icons
branch_icon=$(printf '\xee\x82\xa0')   #

# Colors (24-bit RGB, interpreted via printf %b)
reset='\033[0m'
bold_cyan='\033[38;2;86;182;194m'
bold_purple='\033[38;2;180;140;255m'
bold_green='\033[38;2;0;175;80m'
bold_yellow='\033[38;2;230;200;0m'
bold_orange='\033[38;2;255;176;85m'
bold_red='\033[38;2;255;85;85m'
bold_blue='\033[38;2;0;153;255m'
dim='\033[2m'

branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

# Git status
git_part=""
if [ -n "$branch" ]; then
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  staged=$(echo "$dirty" | grep -c '^[MADRC]' 2>/dev/null || echo 0)
  modified=$(echo "$dirty" | grep -c '^.[MD]' 2>/dev/null || echo 0)
  untracked=$(echo "$dirty" | grep -c '^??' 2>/dev/null || echo 0)
  deleted=$(echo "$dirty" | grep -cE '^.D|^D.' 2>/dev/null || echo 0)

  git_flags=""
  [ "$staged" -gt 0 ]    2>/dev/null && git_flags="${git_flags}${bold_green}+${staged}${reset}"
  [ "$modified" -gt 0 ]  2>/dev/null && git_flags="${git_flags}${bold_yellow}!${modified}${reset}"
  [ "$deleted" -gt 0 ]   2>/dev/null && git_flags="${git_flags}${bold_red}✘${deleted}${reset}"
  [ "$untracked" -gt 0 ] 2>/dev/null && git_flags="${git_flags}${dim}?${untracked}${reset}"

  if [ -z "$dirty" ]; then
    git_clean="${bold_green}✓${reset}"
  else
    git_clean="${git_flags}"
  fi

  # Ahead / behind upstream
  ahead_behind=""
  upstream=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  if [ -n "$upstream" ]; then
    ahead=$(git -C "$cwd" --no-optional-locks rev-list --count "@{u}..HEAD" 2>/dev/null)
    behind=$(git -C "$cwd" --no-optional-locks rev-list --count "HEAD..@{u}" 2>/dev/null)
    [ "${ahead:-0}" -gt 0 ]  2>/dev/null && ahead_behind="${ahead_behind}${bold_cyan}⇡${ahead}${reset}"
    [ "${behind:-0}" -gt 0 ] 2>/dev/null && ahead_behind="${ahead_behind}${bold_yellow}⇣${behind}${reset}"
  fi

  git_part=" ${bold_purple}${branch_icon} ${branch}${reset} ${git_clean}${ahead_behind}"
fi

# Runtime versions
runtime_parts=""

if [ -f "$cwd/package.json" ] && command -v node >/dev/null 2>&1; then
  node_ver=$(node --version 2>/dev/null | sed 's/^v//')
  [ -n "$node_ver" ] && runtime_parts="${runtime_parts} ${dim}⬡ ${node_ver}${reset}"
fi

if [ -f "$cwd/go.mod" ] && command -v go >/dev/null 2>&1; then
  go_ver=$(go version 2>/dev/null | awk '{print $3}' | sed 's/^go//')
  [ -n "$go_ver" ] && runtime_parts="${runtime_parts} ${dim}🐹 ${go_ver}${reset}"
fi

if { [ -f "$cwd/.python-version" ] || [ -f "$cwd/requirements.txt" ] || [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/Pipfile" ]; } && command -v python3 >/dev/null 2>&1; then
  py_ver=$(python3 --version 2>/dev/null | awk '{print $2}')
  [ -n "$py_ver" ] && runtime_parts="${runtime_parts} ${dim}🐍 ${py_ver}${reset}"
fi

if [ -f "$cwd/Cargo.toml" ] && command -v rustc >/dev/null 2>&1; then
  rust_ver=$(rustc --version 2>/dev/null | awk '{print $2}')
  [ -n "$rust_ver" ] && runtime_parts="${runtime_parts} ${dim}🦀 ${rust_ver}${reset}"
fi

# Context window size label
ctx_size_label=""
if [ -n "$ctx_size" ]; then
  if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
    ctx_size_label=" ($(( ctx_size / 1000000 ))M)"
  elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
    ctx_size_label=" ($(( ctx_size / 1000 ))k)"
  fi
fi

# Color by percentage
_color_for_pct() {
  local pct="$1"
  local pct_int
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null)
  if [ "${pct_int:-0}" -ge 90 ]; then
    echo "$bold_red"
  elif [ "${pct_int:-0}" -ge 70 ]; then
    echo "$bold_yellow"
  elif [ "${pct_int:-0}" -ge 50 ]; then
    echo "$bold_orange"
  else
    echo "$bold_green"
  fi
}

# Build dot bar (10 dots, each = 10%)
_dots() {
  local pct="$1"
  local color="$2"
  local filled
  filled=$(( $(printf '%.0f' "$pct") / 10 ))
  local bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      bar="${bar}${color}>${reset}"
    else
      bar="${bar}${dim}-${reset}"
    fi
  done
  echo "$bar"
}

# Context window usage: inline with pencil emoji, yellow, leftmost
ctx_inline=""
if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct" 2>/dev/null)
  ctx_inline="${bold_yellow}✏️ ${pct_int}%${reset}"
fi

# Line 1: dir + git + runtime + model + ctx%
line1="${bold_cyan}${truncated}${reset}${git_part}${runtime_parts}  ${bold_blue}${model}${dim}${ctx_size_label}${reset}  ${ctx_inline}"

# Rate limit: 5-hour (line 2)
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_line=""
if [ -n "$five_pct" ]; then
  five_color=$(_color_for_pct "$five_pct")
  five_bar=$(_dots "$five_pct" "$five_color")
  five_int=$(printf '%.0f' "$five_pct")
  reset_label=""
  if [ -n "$five_resets" ]; then
    reset_label=" ${dim}$(date -r "$five_resets" "+%H:%M")${reset}"
  fi
  five_line="${dim}current${reset} ${five_bar} ${five_color}${five_int}%${reset}${reset_label}"
fi

# Rate limit: 7-day (line 3)
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
week_line=""
if [ -n "$week_pct" ]; then
  week_color=$(_color_for_pct "$week_pct")
  week_bar=$(_dots "$week_pct" "$week_color")
  week_int=$(printf '%.0f' "$week_pct")
  reset_label=""
  if [ -n "$week_resets" ]; then
    reset_label=" ${dim}$(LC_ALL=C date -r "$week_resets" "+%b %d %H:%M")${reset}"
  fi
  week_line="${dim}weekly${reset}  ${week_bar} ${week_color}${week_int}%${reset}${reset_label}"
fi

printf "%b\n" "$line1"
[ -n "$five_line" ] && printf "%b\n" "$five_line"
[ -n "$week_line" ] && printf "%b\n" "$week_line"
