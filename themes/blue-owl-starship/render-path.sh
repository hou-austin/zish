#!/bin/sh
set -eu

blue='1;87;155'
white='255;255;255'
black='0;0;0'
terminal_bg="${ZISH_TERMINAL_BACKGROUND_RGB:-19;23;29}"

fg() {
  printf '\033[38;2;%sm' "$1"
}

fg_bg() {
  printf '\033[38;2;%s;48;2;%sm' "$1" "$2"
}

reset() {
  printf '\033[0m'
}

zish_path_component() {
  printf '%s' "$1"
}

cwd=$(pwd -P)

if [ "$cwd" = "$HOME" ]; then
  set -- ""
elif [ "${cwd#"$HOME"/}" != "$cwd" ]; then
  rest=${cwd#"$HOME"/}
  leaf=${rest##*/}
  if [ "$rest" = "$leaf" ]; then
    set -- "" "$leaf"
  else
    set -- "" "..." "$leaf"
  fi
else
  leaf=${cwd##*/}
  if [ -n "$leaf" ]; then
    set -- "$leaf"
  else
    set -- "/"
  fi
fi

fg_bg "$terminal_bg" "$blue"
printf ''
fg_bg "$white" "$blue"
printf ' '

first=1
for component in "$@"; do
  if [ "$first" -eq 0 ]; then
    fg_bg "$black" "$blue"
    printf '  '
    fg_bg "$white" "$blue"
  fi
  zish_path_component "$component"
  first=0
done

printf ' '
fg "$blue"
printf ' '
reset
