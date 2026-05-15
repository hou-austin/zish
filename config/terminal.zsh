# Terminal-facing defaults that can be controlled safely from Zsh.

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
precmd_functions=(${precmd_functions:#_zish_apply_cursor_style})
add-zsh-hook precmd _zish_apply_cursor_style
_zish_apply_cursor_style
