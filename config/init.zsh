# Zish managed entrypoint for interactive Zsh sessions.

emulate -L zsh

if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || exit 0
fi

_zish_init_source="${${(%):-%N}:A}"
typeset -g ZISH_ROOT="${ZISH_ROOT:-${_zish_init_source:h:h}}"
unset _zish_init_source

if [[ -r "$ZISH_ROOT/config/local.zsh" ]]; then
  source "$ZISH_ROOT/config/local.zsh"
fi

if [[ -r "$ZISH_ROOT/config/tools.zsh" ]]; then
  source "$ZISH_ROOT/config/tools.zsh"
fi

if [[ -r "$ZISH_ROOT/config/starship.zsh" ]]; then
  source "$ZISH_ROOT/config/starship.zsh"
fi

if [[ -d "$ZISH_ROOT/config/local.d" ]]; then
  for _zish_local_file in "$ZISH_ROOT"/config/local.d/*.zsh(N); do
    source "$_zish_local_file"
  done
  unset _zish_local_file
fi
