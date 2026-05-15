# Modern CLI tool integration for interactive Zsh sessions.

emulate -L zsh

if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || exit 0
fi

if [[ -z "${ZISH_ROOT:-}" ]]; then
  _zish_tools_source="${${(%):-%N}:A}"
  typeset -g ZISH_ROOT="${_zish_tools_source:h:h}"
  unset _zish_tools_source
fi

if [[ -z "${ZISH_DISABLE_RIPGREP_CONFIG:-}" && -z "${RIPGREP_CONFIG_PATH:-}" && -r "$ZISH_ROOT/config/ripgreprc" ]]; then
  export RIPGREP_CONFIG_PATH="$ZISH_ROOT/config/ripgreprc"
fi

if [[ -z "${ZISH_DISABLE_BAT_CONFIG:-}" && -z "${BAT_CONFIG_PATH:-}" && -r "$ZISH_ROOT/config/bat.conf" ]]; then
  export BAT_CONFIG_PATH="$ZISH_ROOT/config/bat.conf"
fi

if (( $+commands[eza] )) && [[ -z "${ZISH_DISABLE_EZA_ALIASES:-}" ]]; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza --long --group --git --group-directories-first --icons=auto'
  alias la='eza --long --all --group --git --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi

if (( $+commands[bat] )); then
  _zish_bat_cmd='bat'
elif (( $+commands[batcat] )); then
  _zish_bat_cmd='batcat'
  alias bat='batcat'
else
  _zish_bat_cmd=''
fi

if [[ -n "$_zish_bat_cmd" && -z "${ZISH_DISABLE_BAT_ALIASES:-}" ]]; then
  alias cat="$_zish_bat_cmd --paging=never --style=plain"
  alias bathelp="$_zish_bat_cmd --plain --language=help"
fi
unset _zish_bat_cmd

if (( $+commands[difft] )) && [[ -z "${ZISH_DISABLE_DIFFTASTIC_GIT:-}" && -z "${GIT_EXTERNAL_DIFF:-}" ]]; then
  export GIT_EXTERNAL_DIFF='difft'
fi
