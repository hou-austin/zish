#!/bin/sh
set -eu

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

first=1
for component in "$@"; do
  if [ "$first" -eq 0 ]; then
    printf '  '
  fi
  zish_path_component "$component"
  first=0
done
