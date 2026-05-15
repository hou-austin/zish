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

_zish_source_first_readable_tool_file() {
  local _zish_tool_name="$1"
  shift

  local _zish_tool_file
  for _zish_tool_file in "$@"; do
    if [[ -r "$_zish_tool_file" ]]; then
      source "$_zish_tool_file" || print -u2 "zish: failed to load $_zish_tool_name from $_zish_tool_file"
      return 0
    fi
  done

  return 1
}

if (( $+commands[fzf] )) && [[ -o zle && -t 0 && -t 1 && -z "${ZISH_DISABLE_FZF_INTEGRATION:-}" ]]; then
  if _zish_fzf_init="$(fzf --zsh 2>/dev/null)"; then
    eval "$_zish_fzf_init"
  else
    typeset -a _zish_fzf_completion_files _zish_fzf_key_binding_files
    _zish_fzf_completion_files=()
    _zish_fzf_key_binding_files=()
    for _zish_fzf_root in \
      "${HOMEBREW_PREFIX:-}/opt/fzf/shell" \
      "${HOMEBREW_PREFIX:-}/share/fzf/shell" \
      /opt/homebrew/opt/fzf/shell \
      /opt/homebrew/share/fzf/shell \
      /usr/local/opt/fzf/shell \
      /usr/local/share/fzf/shell \
      /home/linuxbrew/.linuxbrew/opt/fzf/shell \
      /home/linuxbrew/.linuxbrew/share/fzf/shell \
      /usr/share/fzf \
      /usr/share/doc/fzf/examples; do
      [[ -n "$_zish_fzf_root" ]] || continue
      _zish_fzf_completion_files+=("$_zish_fzf_root/completion.zsh")
      _zish_fzf_key_binding_files+=("$_zish_fzf_root/key-bindings.zsh")
    done
    _zish_source_first_readable_tool_file fzf-completion "${_zish_fzf_completion_files[@]}"
    _zish_source_first_readable_tool_file fzf-key-bindings "${_zish_fzf_key_binding_files[@]}"
    unset _zish_fzf_completion_files _zish_fzf_key_binding_files _zish_fzf_root
  fi
  unset _zish_fzf_init
fi

if (( $+commands[zoxide] )) && [[ -z "${ZISH_DISABLE_ZOXIDE_INTEGRATION:-}" ]]; then
  _zish_zoxide_cmd="${ZISH_ZOXIDE_CMD:-cd}"
  if ! _zish_zoxide_init="$(zoxide init zsh --cmd "$_zish_zoxide_cmd" 2>/dev/null)"; then
    print -u2 "zish: failed to initialize zoxide"
  else
    eval "$_zish_zoxide_init"
  fi
  unset _zish_zoxide_cmd _zish_zoxide_init
fi

if (( $+commands[atuin] )) && [[ -z "${ZISH_DISABLE_ATUIN_INTEGRATION:-}" ]]; then
  if ! _zish_atuin_init="$(atuin init zsh 2>/dev/null)"; then
    print -u2 "zish: failed to initialize atuin"
  else
    eval "$_zish_atuin_init"
  fi
  unset _zish_atuin_init
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

unfunction _zish_source_first_readable_tool_file
