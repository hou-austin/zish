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

_zish_rgb_to_hex() {
  emulate -L zsh

  local _zish_rgb="${1:-}"
  local -a _zish_rgb_parts
  local _zish_rgb_part
  local -a _zish_rgb_values

  _zish_rgb_parts=("${(@s:;:)_zish_rgb}")
  [[ "${#_zish_rgb_parts[@]}" -eq 3 ]] || return 1

  for _zish_rgb_part in "${_zish_rgb_parts[@]}"; do
    [[ "$_zish_rgb_part" == <-> ]] || return 1
    _zish_rgb_values+=("$(( 10#$_zish_rgb_part ))")
    (( _zish_rgb_values[-1] >= 0 && _zish_rgb_values[-1] <= 255 )) || return 1
  done

  printf '#%02X%02X%02X\n' "${_zish_rgb_values[@]}"
}

_zish_starship_config_with_terminal_bg() {
  emulate -L zsh

  local _zish_config_source="$1"
  local _zish_terminal_bg_hex
  local _zish_default_terminal_bg_hex
  local _zish_cache_root
  local _zish_terminal_bg_name
  local _zish_config_cache
  local _zish_config_tmp
  local _zish_config_line

  [[ -n "${ZISH_TERMINAL_BACKGROUND_RGB:-}" ]] || {
    print -r -- "$_zish_config_source"
    return 0
  }

  _zish_terminal_bg_hex="$(_zish_rgb_to_hex "$ZISH_TERMINAL_BACKGROUND_RGB" 2>/dev/null)" || {
    print -r -- "$_zish_config_source"
    return 0
  }

  case "$_zish_config_source" in
    *starship-light.toml) _zish_default_terminal_bg_hex="#FAFAFA" ;;
    *) _zish_default_terminal_bg_hex="#13171D" ;;
  esac

  if [[ "$_zish_terminal_bg_hex" = "$_zish_default_terminal_bg_hex" ]]; then
    print -r -- "$_zish_config_source"
    return 0
  fi

  _zish_cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/zish/starship"
  _zish_terminal_bg_name="${_zish_terminal_bg_hex#\#}"
  _zish_config_cache="$_zish_cache_root/${_zish_config_source:t:r}-$_zish_terminal_bg_name.toml"

  if [[ ! -r "$_zish_config_cache" || "$_zish_config_source" -nt "$_zish_config_cache" ]]; then
    mkdir -p "$_zish_cache_root" 2>/dev/null || {
      print -r -- "$_zish_config_source"
      return 0
    }

    _zish_config_tmp="$_zish_config_cache.tmp.$$"
    while IFS= read -r _zish_config_line || [[ -n "$_zish_config_line" ]]; do
      case "$_zish_config_line" in
        'terminal_bg = '*)
          print -r -- "terminal_bg = \"$_zish_terminal_bg_hex\""
          ;;
        *)
          print -r -- "$_zish_config_line"
          ;;
      esac
    done <"$_zish_config_source" >"$_zish_config_tmp" && mv "$_zish_config_tmp" "$_zish_config_cache"
    rm -f "$_zish_config_tmp" 2>/dev/null || true
  fi

  if [[ -r "$_zish_config_cache" ]]; then
    print -r -- "$_zish_config_cache"
  else
    print -r -- "$_zish_config_source"
  fi
}

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

  if [[ "$_zish_managed_theme" = blue-owl-starship ]]; then
    _zish_managed_config="$(_zish_starship_config_with_terminal_bg "$_zish_managed_config")"
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
