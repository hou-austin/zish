# Terminal-facing defaults that can be controlled safely from Zsh.

zmodload -F zsh/datetime b:EPOCHSECONDS 2>/dev/null || true

_zish_detect_system_appearance() {
  case "${ZISH_SYSTEM_APPEARANCE:l}" in
    light|dark) print -r -- "${ZISH_SYSTEM_APPEARANCE:l}"; return 0 ;;
  esac

  case "$(uname -s 2>/dev/null)" in
    Darwin)
      if (( $+commands[defaults] )) && defaults read -g AppleInterfaceStyle 2>/dev/null | command grep -qi '^Dark$'; then
        print -r -- dark
      else
        print -r -- light
      fi
      ;;
    Linux)
      if (( $+commands[gsettings] )); then
        _zish_color_scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
        if [[ "$_zish_color_scheme" == *dark* ]]; then
          print -r -- dark
          unset _zish_color_scheme
          return 0
        elif [[ "$_zish_color_scheme" == *light* ]]; then
          print -r -- light
          unset _zish_color_scheme
          return 0
        fi
        unset _zish_color_scheme
      fi
      print -r -- dark
      ;;
    *)
      print -r -- dark
      ;;
  esac
}

typeset -g _ZISH_TERMINAL_BACKGROUND_RGB_MANUAL=0
if [[ -n "${ZISH_TERMINAL_BACKGROUND_RGB:-}" ]]; then
  typeset -g _ZISH_TERMINAL_BACKGROUND_RGB_MANUAL=1
fi

_zish_refresh_terminal_appearance() {
  integer _zish_now=${EPOCHSECONDS:-0}

  if [[ -n "${_ZISH_APPEARANCE_CHECKED_AT:-}" && "$_zish_now" -gt 0 && $(( _zish_now - _ZISH_APPEARANCE_CHECKED_AT )) -lt 10 ]]; then
    return 0
  fi

  typeset -g _ZISH_APPEARANCE_CHECKED_AT="$_zish_now"
  typeset -g ZISH_SYSTEM_APPEARANCE_CURRENT="$(_zish_detect_system_appearance)"

  if [[ "$_ZISH_TERMINAL_BACKGROUND_RGB_MANUAL" -eq 1 ]]; then
    return 0
  fi

  case "$ZISH_SYSTEM_APPEARANCE_CURRENT" in
    light)
      export ZISH_TERMINAL_BACKGROUND_RGB="${ZISH_TERMINAL_LIGHT_BACKGROUND_RGB:-250;250;250}"
      ;;
    *)
      export ZISH_TERMINAL_BACKGROUND_RGB="${ZISH_TERMINAL_DARK_BACKGROUND_RGB:-19;23;29}"
      ;;
  esac
}

_zish_apply_cursor_style() {
  [[ -t 1 ]] || return 0

  case "${ZISH_CURSOR_STYLE:-underline}" in
    underline) print -n -- $'\e[4 q' ;;
    beam) print -n -- $'\e[6 q' ;;
    block) print -n -- $'\e[2 q' ;;
    blinking_underline) print -n -- $'\e[3 q' ;;
    blinking_beam) print -n -- $'\e[5 q' ;;
    blinking_block) print -n -- $'\e[1 q' ;;
    none|'') return 0 ;;
  esac
}

autoload -Uz add-zsh-hook
precmd_functions=(${precmd_functions:#_zish_refresh_terminal_appearance})
add-zsh-hook precmd _zish_refresh_terminal_appearance
precmd_functions=(${precmd_functions:#_zish_apply_cursor_style})
add-zsh-hook precmd _zish_apply_cursor_style
_zish_refresh_terminal_appearance
_zish_apply_cursor_style
