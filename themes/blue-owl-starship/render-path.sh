#!/bin/sh
set -eu

blue='1;87;155'
white='255;255;255'

zish_system_appearance() {
  case "${ZISH_SYSTEM_APPEARANCE:-}" in
    light|LIGHT|Light) printf 'light\n'; return 0 ;;
    dark|DARK|Dark) printf 'dark\n'; return 0 ;;
  esac

  case "$(uname -s 2>/dev/null)" in
    Darwin)
      if command -v defaults >/dev/null 2>&1 && defaults read -g AppleInterfaceStyle 2>/dev/null | grep -qi '^Dark$'; then
        printf 'dark\n'
      else
        printf 'light\n'
      fi
      ;;
    Linux)
      if command -v gsettings >/dev/null 2>&1; then
        color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
        case "$color_scheme" in
          *dark*) printf 'dark\n'; return 0 ;;
          *light*) printf 'light\n'; return 0 ;;
        esac
      fi
      printf 'dark\n'
      ;;
    *)
      printf 'dark\n'
      ;;
  esac
}

if [ -n "${ZISH_TERMINAL_BACKGROUND_RGB:-}" ]; then
  terminal_bg=$ZISH_TERMINAL_BACKGROUND_RGB
elif [ "$(zish_system_appearance)" = light ]; then
  terminal_bg="${ZISH_TERMINAL_LIGHT_BACKGROUND_RGB:-250;250;250}"
else
  terminal_bg="${ZISH_TERMINAL_DARK_BACKGROUND_RGB:-19;23;29}"
fi

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
    fg_bg "$terminal_bg" "$blue"
    printf '  '
    fg_bg "$white" "$blue"
  fi
  zish_path_component "$component"
  first=0
done

printf ' '
reset
fg "$blue"
printf ''
reset
