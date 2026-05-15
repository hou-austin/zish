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
_zish_starship_config_custom=0
_zish_starship_refresh_enabled=0

if [[ -n "${ZISH_STARSHIP_CONFIG:-}" ]]; then
  _zish_starship_config="$ZISH_STARSHIP_CONFIG"
  _zish_starship_config_custom=1
else
  _zish_starship_config="$ZISH_ROOT/themes/$_zish_theme/starship.toml"
fi

_zish_refresh_starship_config() {
  [[ -z "${ZISH_STARSHIP_CONFIG:-}" ]] || return 0
  [[ -z "${STARSHIP_CONFIG:-}" || "${STARSHIP_CONFIG:-}" = "${_ZISH_STARSHIP_CONFIG_MANAGED:-}" ]] || return 0

  _zish_managed_theme="${ZISH_THEME:-blue-owl-starship}"
  _zish_managed_config="$ZISH_ROOT/themes/$_zish_managed_theme/starship.toml"

  if [[ "$_zish_managed_theme" = blue-owl-starship && "${ZISH_SYSTEM_APPEARANCE_CURRENT:-}" = light ]]; then
    _zish_light_config="$ZISH_ROOT/themes/blue-owl-starship/starship-light.toml"
    if [[ -r "$_zish_light_config" ]]; then
      _zish_managed_config="$_zish_light_config"
    fi
    unset _zish_light_config
  fi

  if [[ -r "$_zish_managed_config" ]]; then
    export STARSHIP_CONFIG="$_zish_managed_config"
    typeset -g _ZISH_STARSHIP_CONFIG_MANAGED="$_zish_managed_config"
  fi

  unset _zish_managed_theme _zish_managed_config
}

if [[ -z "${STARSHIP_CONFIG:-}" && "$_zish_starship_config_custom" -eq 0 ]]; then
  _zish_starship_refresh_enabled=1
  _zish_refresh_starship_config
elif [[ -z "${STARSHIP_CONFIG:-}" && -r "$_zish_starship_config" ]]; then
  export STARSHIP_CONFIG="$_zish_starship_config"
fi

unset _zish_theme _zish_starship_config _zish_starship_config_custom

if (( $+functions[prompt_starship_precmd] )); then
  unset _zish_starship_refresh_enabled
  return 0
fi

if [[ "$_zish_starship_refresh_enabled" -eq 1 ]]; then
  autoload -Uz add-zsh-hook
  precmd_functions=(${precmd_functions:#_zish_refresh_starship_config})
  add-zsh-hook precmd _zish_refresh_starship_config
fi

unset _zish_starship_refresh_enabled

eval "$(starship init zsh)"
