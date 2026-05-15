# Starship prompt integration for Zish.

emulate -L zsh

if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || exit 0
fi

if ! (( $+commands[starship] )); then
  if [[ -n "${ZISH_WARN_MISSING_STARSHIP:-}" ]]; then
    print -ru2 -- "zish: starship not found; prompt not initialized"
  fi
  return 0
fi

if [[ -z "${ZISH_ROOT:-}" ]]; then
  _zish_starship_source="${${(%):-%N}:A}"
  typeset -g ZISH_ROOT="${_zish_starship_source:h:h}"
  unset _zish_starship_source
fi

_zish_theme="${ZISH_THEME:-blue-owl-starship}"
_zish_starship_config="${ZISH_STARSHIP_CONFIG:-$ZISH_ROOT/themes/$_zish_theme/starship.toml}"

if [[ -z "${STARSHIP_CONFIG:-}" && -r "$_zish_starship_config" ]]; then
  export STARSHIP_CONFIG="$_zish_starship_config"
fi

unset _zish_theme _zish_starship_config

if [[ -n "${STARSHIP_SHELL:-}" ]] || (( $+functions[prompt_starship_precmd] )); then
  return 0
fi

eval "$(starship init zsh)"
