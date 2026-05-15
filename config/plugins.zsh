# Managed Zsh plugin loading for interactive sessions.

emulate -L zsh

if [[ ! -o interactive ]]; then
  return 0 2>/dev/null || exit 0
fi

if [[ -z "${ZISH_ROOT:-}" ]]; then
  _zish_plugins_source="${${(%):-%N}:A}"
  typeset -g ZISH_ROOT="${_zish_plugins_source:h:h}"
  unset _zish_plugins_source
fi

_zish_source_first_readable_plugin() {
  local _zish_plugin_name="$1"
  shift

  local _zish_plugin_file
  for _zish_plugin_file in "$@"; do
    if [[ -r "$_zish_plugin_file" ]]; then
      source "$_zish_plugin_file" || print -u2 "zish: failed to load $_zish_plugin_name from $_zish_plugin_file"
      return 0
    fi
  done

  [[ -n "${ZISH_WARN_MISSING_PLUGINS:-}" ]] && print -u2 "zish: $_zish_plugin_name is not installed"
  return 1
}

typeset -a _zish_share_roots
_zish_share_roots=()
[[ -n "${HOMEBREW_PREFIX:-}" ]] && _zish_share_roots+=("$HOMEBREW_PREFIX/share")
_zish_share_roots+=(
  /opt/homebrew/share
  /usr/local/share
  /home/linuxbrew/.linuxbrew/share
  /usr/share
)

typeset -a _zish_autosuggestions_files _zish_syntax_highlighting_files
_zish_autosuggestions_files=()
_zish_syntax_highlighting_files=()

for _zish_share_root in "${_zish_share_roots[@]}"; do
  _zish_autosuggestions_files+=("$_zish_share_root/zsh-autosuggestions/zsh-autosuggestions.zsh")
  _zish_syntax_highlighting_files+=("$_zish_share_root/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")
done

_zish_autosuggestions_files+=(
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
)

_zish_syntax_highlighting_files+=(
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
)

if [[ -z "${ZISH_DISABLE_ZSH_AUTOSUGGESTIONS:-}" ]]; then
  _zish_source_first_readable_plugin zsh-autosuggestions "${_zish_autosuggestions_files[@]}"
fi

unfunction _zish_source_first_readable_plugin
unset _zish_share_roots _zish_share_root _zish_autosuggestions_files

if [[ -z "${ZISH_DISABLE_ZSH_SYNTAX_HIGHLIGHTING:-}" ]]; then
  for _zish_plugin_file in "${_zish_syntax_highlighting_files[@]}"; do
    if [[ -r "$_zish_plugin_file" ]]; then
      source "$_zish_plugin_file" || print -u2 "zish: failed to load zsh-syntax-highlighting from $_zish_plugin_file"
      return 0 2>/dev/null || exit 0
    fi
  done
  [[ -n "${ZISH_WARN_MISSING_PLUGINS:-}" ]] && print -u2 "zish: zsh-syntax-highlighting is not installed"
fi
