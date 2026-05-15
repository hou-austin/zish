#!/bin/sh
set -eu

DRY_RUN=0
YES=0
NO_PACKAGE_INSTALL=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--dry-run] [--yes] [--no-package-install]

Sets up the managed Zish hook and installs/configures supported CLI tools:
zsh, starship, eza, bat, ripgrep, difftastic, fzf, zoxide, atuin,
zsh-autosuggestions, and zsh-syntax-highlighting.

Environment overrides:
  ZISH_INSTALL_DIR  Managed install path. Default: $XDG_DATA_HOME/zish/current
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes) YES=1 ;;
    --no-package-install) NO_PACKAGE_INSTALL=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

SOURCE_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
INSTALL_ROOT="${ZISH_INSTALL_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zish/current}"
INSTALL_PARENT=$(dirname -- "$INSTALL_ROOT")
INSTALL_BASENAME=$(basename -- "$INSTALL_ROOT")
if [ -d "$INSTALL_PARENT" ]; then
  INSTALL_ROOT=$(CDPATH= cd -- "$INSTALL_PARENT" && printf '%s/%s\n' "$(pwd -P)" "$INSTALL_BASENAME")
else
  case "$INSTALL_PARENT" in
    /*) INSTALL_ROOT="$INSTALL_PARENT/$INSTALL_BASENAME" ;;
    *) INSTALL_ROOT="$PWD/$INSTALL_PARENT/$INSTALL_BASENAME" ;;
  esac
fi
unset INSTALL_PARENT INSTALL_BASENAME
# shellcheck source=lib/setup/packages.sh
. "$SOURCE_ROOT/lib/setup/packages.sh"

TOOLS="zsh starship eza bat ripgrep difftastic fzf zoxide atuin zsh-autosuggestions zsh-syntax-highlighting"
MANAGER=$(zish_detect_package_manager)
MISSING_TOOLS=""
PACKAGES=""
UNSUPPORTED_TOOLS=""
FONT_ACTION=none
FONT_NOTE=""
FONT_INSTALL_LABEL=""
FONT_READY=0
FONT_DISPLAY_NAME="JetBrainsMono Nerd Font"
FONT_CASK="font-jetbrains-mono-nerd-font"
FONT_ARCHIVE="JetBrainsMono.zip"
FONT_DIR_NAME="JetBrainsMonoNerdFont"
TERMINAL_FONT_NAME="JetBrainsMono Nerd Font Mono"
TERMINAL_FONT_ACTION=none
TERMINAL_FONT_NOTE=""

for tool in $TOOLS; do
  if zish_tool_command_exists "$tool"; then
    continue
  fi

  MISSING_TOOLS="${MISSING_TOOLS}${MISSING_TOOLS:+ }$tool"

  if [ "$NO_PACKAGE_INSTALL" -eq 0 ] && [ "$MANAGER" != none ]; then
    if package=$(zish_package_for_tool "$MANAGER" "$tool"); then
      PACKAGES="${PACKAGES}${PACKAGES:+ }$package"
    else
      UNSUPPORTED_TOOLS="${UNSUPPORTED_TOOLS}${UNSUPPORTED_TOOLS:+ }$tool"
    fi
  fi
done

zish_is_wsl() {
  [ -r /proc/version ] && grep -qi microsoft /proc/version
}

zish_macos_jetbrains_mono_installed() {
  if command -v brew >/dev/null 2>&1 && brew list --cask "$FONT_CASK" >/dev/null 2>&1; then
    return 0
  fi

  find "$HOME/Library/Fonts" -maxdepth 1 -name 'JetBrainsMono*NerdFontMono*.ttf' 2>/dev/null | grep -q .
}

zish_linux_jetbrains_mono_installed() {
  if command -v fc-match >/dev/null 2>&1; then
    fc-match -f '%{family}\n' "$TERMINAL_FONT_NAME" 2>/dev/null | grep -qi 'JetBrains.*Nerd Font.*Mono'
  else
    find "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" -name 'JetBrainsMono*NerdFontMono*.ttf' 2>/dev/null | grep -q .
  fi
}

zish_install_jetbrains_mono_linux() {
  tmp_dir=$(mktemp -d)
  font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/$FONT_DIR_NAME"

  mkdir -p "$font_dir"
  curl -fsSL -o "$tmp_dir/$FONT_ARCHIVE" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_ARCHIVE"
  unzip -oq "$tmp_dir/$FONT_ARCHIVE" -d "$font_dir"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi

  rm -rf "$tmp_dir"
}

zish_current_user() {
  id -un 2>/dev/null || printf '%s\n' "${USER:-}"
}

zish_current_login_shell() {
  login_user=$(zish_current_user)
  [ -n "$login_user" ] || return 1

  if command -v getent >/dev/null 2>&1; then
    getent passwd "$login_user" | awk -F: '{ print $7; exit }'
  elif [ -r /etc/passwd ]; then
    awk -F: -v login_user="$login_user" '$1 == login_user { print $7; exit }' /etc/passwd
  else
    return 1
  fi
}

zish_shell_basename_is_zsh() {
  case "$(basename -- "$1")" in
    zsh) return 0 ;;
    *) return 1 ;;
  esac
}

zish_shell_is_listed() {
  [ ! -r /etc/shells ] && return 0
  grep -Fx "$1" /etc/shells >/dev/null 2>&1
}

zish_login_zsh_path() {
  zsh_command=$(command -v zsh 2>/dev/null) || return 1

  if zish_shell_is_listed "$zsh_command"; then
    printf '%s\n' "$zsh_command"
    return 0
  fi

  if [ -r /etc/shells ]; then
    zsh_shell=$(awk '/^\// && /\/zsh$/ { print; exit }' /etc/shells)
    if [ -n "$zsh_shell" ] && [ -x "$zsh_shell" ]; then
      printf '%s\n' "$zsh_shell"
      return 0
    fi
  fi

  printf '%s\n' "$zsh_command"
}

zish_configure_apple_terminal_font() {
  osascript <<'APPLESCRIPT'
tell application "Terminal"
  set font name of default settings to "JetBrainsMono Nerd Font Mono"
  if (count of windows) > 0 then
    set font name of current settings of selected tab of front window to "JetBrainsMono Nerd Font Mono"
  end if
end tell
APPLESCRIPT
}

case "$(uname -s)" in
  Darwin)
    if zish_macos_jetbrains_mono_installed; then
      FONT_NOTE="$FONT_DISPLAY_NAME is installed"
      FONT_READY=1
    elif [ "$NO_PACKAGE_INSTALL" -eq 1 ]; then
      FONT_NOTE="$FONT_DISPLAY_NAME install skipped by --no-package-install"
    elif [ "$MANAGER" = brew ]; then
      FONT_ACTION=brew-cask
      FONT_INSTALL_LABEL="brew install --cask $FONT_CASK"
      FONT_READY=1
    else
      FONT_NOTE="install $FONT_DISPLAY_NAME manually and set it in your terminal"
    fi
    ;;
  Linux)
    if zish_is_wsl; then
      FONT_NOTE="WSL detected; install $FONT_DISPLAY_NAME on the Windows host and set it in Windows Terminal"
    elif zish_linux_jetbrains_mono_installed; then
      FONT_NOTE="$FONT_DISPLAY_NAME is installed"
      FONT_READY=1
    elif [ "$NO_PACKAGE_INSTALL" -eq 1 ]; then
      FONT_NOTE="$FONT_DISPLAY_NAME install skipped by --no-package-install"
    elif command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
      FONT_ACTION=linux-user
      FONT_INSTALL_LABEL="download $FONT_ARCHIVE into ${XDG_DATA_HOME:-$HOME/.local/share}/fonts/$FONT_DIR_NAME"
      FONT_READY=1
    else
      FONT_NOTE="install $FONT_DISPLAY_NAME manually; curl and unzip are required for automatic font install"
    fi
    ;;
  *)
    FONT_NOTE="install $FONT_DISPLAY_NAME manually and set it in your terminal"
    ;;
esac

case "$(uname -s)" in
  Darwin)
    if [ "${ZISH_CONFIGURE_TERMINAL_FONT:-1}" = 0 ]; then
      TERMINAL_FONT_NOTE="terminal font configuration skipped by ZISH_CONFIGURE_TERMINAL_FONT=0"
    elif [ "${TERM_PROGRAM:-}" = Apple_Terminal ] && [ "$FONT_READY" -eq 1 ] && command -v osascript >/dev/null 2>&1; then
      TERMINAL_FONT_ACTION=apple-terminal
      TERMINAL_FONT_NOTE="Apple Terminal active profile -> $TERMINAL_FONT_NAME"
    elif [ "${TERM_PROGRAM:-}" = Apple_Terminal ]; then
      TERMINAL_FONT_NOTE="Apple Terminal font not changed because $FONT_DISPLAY_NAME is not installed"
    else
      TERMINAL_FONT_NOTE="set your terminal profile font to $TERMINAL_FONT_NAME"
    fi
    ;;
  Linux)
    if zish_is_wsl; then
      TERMINAL_FONT_NOTE="set Windows Terminal font.face to $TERMINAL_FONT_NAME on the Windows host"
    else
      TERMINAL_FONT_NOTE="set your terminal profile font to $TERMINAL_FONT_NAME"
    fi
    ;;
  *)
    TERMINAL_FONT_NOTE="set your terminal profile font to $TERMINAL_FONT_NAME"
    ;;
esac

LOGIN_SHELL_ACTION=none
LOGIN_SHELL_NOTE=""
LOGIN_SHELL_USER=""
LOGIN_SHELL_BEFORE=""
LOGIN_SHELL_TARGET=""
LOGIN_SHELL_ERROR=""

zish_print_login_shell_manual_step() {
  target_shell="$1"
  target_user="$2"

  [ -n "$target_shell" ] || return 0

  if [ -n "$target_user" ]; then
    printf 'To make Zsh your login shell, run: chsh -s %s %s\n' "$target_shell" "$target_user" >&2
    if command -v sudo >/dev/null 2>&1; then
      printf 'If your system requires administrator privileges, run: sudo chsh -s %s %s\n' "$target_shell" "$target_user" >&2
    fi
  else
    printf 'To make Zsh your login shell, run: chsh -s %s "$USER"\n' "$target_shell" >&2
  fi
}

case "$(uname -s)" in
  Linux)
    LOGIN_SHELL_USER=$(zish_current_user)
    LOGIN_SHELL_BEFORE=$(zish_current_login_shell || true)
    if [ -z "$LOGIN_SHELL_USER" ]; then
      LOGIN_SHELL_NOTE="could not determine current user; set login shell manually"
    elif [ -n "$LOGIN_SHELL_BEFORE" ] && zish_shell_basename_is_zsh "$LOGIN_SHELL_BEFORE"; then
      LOGIN_SHELL_NOTE="already zsh ($LOGIN_SHELL_BEFORE)"
    elif ! command -v chsh >/dev/null 2>&1; then
      LOGIN_SHELL_NOTE="chsh not found; set login shell manually after install"
    elif LOGIN_SHELL_TARGET=$(zish_login_zsh_path); then
      if zish_shell_is_listed "$LOGIN_SHELL_TARGET"; then
        LOGIN_SHELL_ACTION=change
        LOGIN_SHELL_NOTE="${LOGIN_SHELL_BEFORE:-unknown} -> $LOGIN_SHELL_TARGET"
      else
        LOGIN_SHELL_NOTE="$LOGIN_SHELL_TARGET is not listed in /etc/shells; add it before changing the login shell"
      fi
    elif [ "$NO_PACKAGE_INSTALL" -eq 0 ] && printf '%s\n' "$PACKAGES" | grep -Eq '(^| )zsh( |$)'; then
      LOGIN_SHELL_ACTION=change-after-install
      LOGIN_SHELL_NOTE="${LOGIN_SHELL_BEFORE:-unknown} -> zsh after package install"
    else
      LOGIN_SHELL_NOTE="zsh not found; install zsh before changing the login shell"
    fi
    ;;
esac

if [ "$(uname -s)" = Darwin ]; then
  BACKUP_ROOT="$HOME/Library/Application Support/zish/backups"
else
  BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/zish/backups"
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
ZSHRC="$HOME/.zshrc"
EXISTING_SYNTAX_HIGHLIGHTING=0
EXISTING_AUTOSUGGESTIONS=0
EXISTING_FZF=0
EXISTING_ZOXIDE=0
EXISTING_ATUIN=0

if [ -f "$ZSHRC" ]; then
  grep -Eq '^# Syntax highlighting should be last$|zsh-syntax-highlighting' "$ZSHRC" && EXISTING_SYNTAX_HIGHLIGHTING=1 || true
  grep -Eq 'zsh-autosuggestions' "$ZSHRC" && EXISTING_AUTOSUGGESTIONS=1 || true
  grep -Eq 'fzf[[:space:]]+--zsh|source[[:space:]].*fzf\.zsh' "$ZSHRC" && EXISTING_FZF=1 || true
  grep -Eq 'zoxide[[:space:]]+init' "$ZSHRC" && EXISTING_ZOXIDE=1 || true
  grep -Eq 'atuin[[:space:]]+init' "$ZSHRC" && EXISTING_ATUIN=1 || true
fi

zish_same_path() {
  [ "$(CDPATH= cd -- "$1" 2>/dev/null && pwd -P)" = "$(CDPATH= cd -- "$2" 2>/dev/null && pwd -P)" ]
}

zish_install_tree_needed() {
  if [ ! -d "$INSTALL_ROOT" ]; then
    return 0
  fi

  ! zish_same_path "$SOURCE_ROOT" "$INSTALL_ROOT"
}

zish_sync_install_tree() {
  if zish_same_path "$SOURCE_ROOT" "$INSTALL_ROOT"; then
    return 0
  fi

  case "$INSTALL_ROOT" in
    /|"") printf 'Refusing unsafe ZISH_INSTALL_DIR: %s\n' "$INSTALL_ROOT" >&2; exit 1 ;;
  esac

  mkdir -p "$INSTALL_ROOT"
  rm -rf \
    "$INSTALL_ROOT/config" \
    "$INSTALL_ROOT/docs" \
    "$INSTALL_ROOT/lib" \
    "$INSTALL_ROOT/themes" \
    "$INSTALL_ROOT/AGENTS.md" \
    "$INSTALL_ROOT/README.md" \
    "$INSTALL_ROOT/bootstrap.sh" \
    "$INSTALL_ROOT/install.sh"

  for path in config docs lib themes AGENTS.md README.md bootstrap.sh install.sh; do
    if [ -e "$SOURCE_ROOT/$path" ]; then
      cp -R "$SOURCE_ROOT/$path" "$INSTALL_ROOT/$path"
    fi
  done
}

_zish_managed_disables=""
if [ "$EXISTING_SYNTAX_HIGHLIGHTING" -eq 1 ]; then
  _zish_managed_disables="${_zish_managed_disables}# Existing syntax highlighting is left after this block so it remains last.
export ZISH_DISABLE_ZSH_SYNTAX_HIGHLIGHTING=1
"
fi
if [ "$EXISTING_AUTOSUGGESTIONS" -eq 1 ]; then
  _zish_managed_disables="${_zish_managed_disables}export ZISH_DISABLE_ZSH_AUTOSUGGESTIONS=1
"
fi
if [ "$EXISTING_FZF" -eq 1 ]; then
  _zish_managed_disables="${_zish_managed_disables}export ZISH_DISABLE_FZF_INTEGRATION=1
"
fi
if [ "$EXISTING_ZOXIDE" -eq 1 ]; then
  _zish_managed_disables="${_zish_managed_disables}export ZISH_DISABLE_ZOXIDE_INTEGRATION=1
"
fi
if [ "$EXISTING_ATUIN" -eq 1 ]; then
  _zish_managed_disables="${_zish_managed_disables}export ZISH_DISABLE_ATUIN_INTEGRATION=1
"
fi

MANAGED_BLOCK="# >>> zish managed block >>>
${_zish_managed_disables}if [ -f \"$INSTALL_ROOT/config/init.zsh\" ]; then
  source \"$INSTALL_ROOT/config/init.zsh\"
fi
# <<< zish managed block <<<"

unset _zish_managed_disables

printf 'Zish setup plan\n'
printf '  source: %s\n' "$SOURCE_ROOT"
printf '  install dir: %s\n' "$INSTALL_ROOT"
printf '  shell hook: %s\n' "$ZSHRC"
printf '  package manager: %s\n' "$MANAGER"

if [ -n "$MISSING_TOOLS" ]; then
  printf '  missing tools: %s\n' "$MISSING_TOOLS"
else
  printf '  missing tools: none\n'
fi

if [ -n "$PACKAGES" ]; then
  INSTALL_CMD=$(zish_install_command "$MANAGER" "$PACKAGES")
  printf '  install command: %s\n' "$INSTALL_CMD"
elif [ "$NO_PACKAGE_INSTALL" -eq 1 ]; then
  printf '  install command: skipped by --no-package-install\n'
else
  printf '  install command: none\n'
fi

if [ "$FONT_ACTION" = none ]; then
  printf '  font: %s\n' "$FONT_NOTE"
else
  printf '  font: %s\n' "$FONT_DISPLAY_NAME"
  printf '  font install: %s\n' "$FONT_INSTALL_LABEL"
fi
printf '  terminal font: %s\n' "$TERMINAL_FONT_NOTE"

if [ -n "$LOGIN_SHELL_NOTE" ]; then
  printf '  login shell: %s\n' "$LOGIN_SHELL_NOTE"
  if [ "$LOGIN_SHELL_ACTION" = change ] && [ -n "$LOGIN_SHELL_TARGET" ]; then
    printf '  login shell command: chsh -s %s %s\n' "$LOGIN_SHELL_TARGET" "$LOGIN_SHELL_USER"
  elif [ "$LOGIN_SHELL_ACTION" = change-after-install ]; then
    printf '  login shell command: resolve zsh after package install, then chsh\n'
  fi
fi

if [ -n "$UNSUPPORTED_TOOLS" ]; then
  printf '  unsupported by detected package manager: %s\n' "$UNSUPPORTED_TOOLS"
fi

if [ -f "$ZSHRC" ]; then
  printf '  backup: %s/.zshrc\n' "$BACKUP_DIR"
else
  printf '  backup: not needed; %s does not exist\n' "$ZSHRC"
fi

if zish_install_tree_needed; then
  if [ -d "$INSTALL_ROOT" ]; then
    printf '  install backup: %s/install-root\n' "$BACKUP_DIR"
  else
    printf '  install backup: not needed; %s does not exist\n' "$INSTALL_ROOT"
  fi
  printf '  install files: sync managed files to %s\n' "$INSTALL_ROOT"
else
  printf '  install files: source is already the install dir\n'
fi

if [ -f "$ZSHRC" ] && grep -Eq 'starship[[:space:]]+init[[:space:]]+zsh|starship init zsh' "$ZSHRC"; then
  printf '  note: existing Starship init detected; Zish will set STARSHIP_CONFIG and skip duplicate init\n'
fi

if [ -f "$ZSHRC" ] && grep -Eq '^[[:space:]]*alias[[:space:]]+(ls|ll|la|lt|cat)=' "$ZSHRC"; then
  printf '  note: existing tool aliases detected; Zish aliases load later and may override them\n'
fi

if [ -f "$ZSHRC" ] && grep -Eq '^[[:space:]]*(alias|function)[[:space:]]+cd[=[:space:]]|^[[:space:]]*cd[[:space:]]*\(\)' "$ZSHRC"; then
  printf '  note: existing cd override detected; Zish zoxide integration loads later and may override it\n'
fi

if [ "$EXISTING_SYNTAX_HIGHLIGHTING" -eq 1 ]; then
  printf '  note: zsh-syntax-highlighting detected; managed block will be inserted before it\n'
fi
if [ "$EXISTING_AUTOSUGGESTIONS" -eq 1 ]; then
  printf '  note: existing zsh-autosuggestions detected; Zish plugin disabled to avoid double-loading\n'
fi
if [ "$EXISTING_FZF" -eq 1 ]; then
  printf '  note: existing fzf integration detected; Zish fzf disabled to avoid double-loading\n'
fi
if [ "$EXISTING_ZOXIDE" -eq 1 ]; then
  printf '  note: existing zoxide integration detected; Zish zoxide disabled to avoid double-loading\n'
fi
if [ "$EXISTING_ATUIN" -eq 1 ]; then
  printf '  note: existing atuin integration detected; Zish atuin disabled to avoid double-loading\n'
fi

if [ "$DRY_RUN" -eq 1 ]; then
  exit 0
fi

if [ "$YES" -ne 1 ]; then
  if { exec 3<>/dev/tty; } 2>/dev/null; then
    printf 'Apply this plan? [y/N] ' >&3
    IFS= read -r answer <&3 || answer=
    exec 3<&-
    exec 3>&-
  else
    printf 'Cannot prompt for confirmation because no terminal is available.\n' >&2
    printf 'Rerun with --yes to approve the plan non-interactively.\n' >&2
    exit 1
  fi
  case "$answer" in
    y|Y|yes|YES) ;;
    *)
      printf 'Cancelled.\n'
      exit 1
      ;;
  esac
fi

if [ -n "$PACKAGES" ]; then
  INSTALL_CMD=$(zish_install_command "$MANAGER" "$PACKAGES")
  sh -c "$INSTALL_CMD"
fi

case "$FONT_ACTION" in
  brew-cask)
    brew install --cask "$FONT_CASK"
    ;;
  linux-user)
    zish_install_jetbrains_mono_linux
    ;;
esac

case "$TERMINAL_FONT_ACTION" in
  apple-terminal)
    zish_configure_apple_terminal_font
    ;;
esac

if [ -f "$ZSHRC" ] || zish_install_tree_needed; then
  mkdir -p "$BACKUP_DIR"
fi

if [ -f "$ZSHRC" ]; then
  cp "$ZSHRC" "$BACKUP_DIR/.zshrc"
  {
    printf 'timestamp=%s\n' "$STAMP"
    printf 'source=%s\n' "$SOURCE_ROOT"
    printf 'install=%s\n' "$INSTALL_ROOT"
    printf 'path=%s\n' "$ZSHRC"
    printf 'backup=%s/.zshrc\n' "$BACKUP_DIR"
    printf 'action=update-managed-zshrc-block\n'
  } >> "$BACKUP_DIR/manifest.env"
fi

if zish_install_tree_needed && [ -d "$INSTALL_ROOT" ]; then
  cp -R "$INSTALL_ROOT" "$BACKUP_DIR/install-root"
  {
    printf 'timestamp=%s\n' "$STAMP"
    printf 'source=%s\n' "$SOURCE_ROOT"
    printf 'install=%s\n' "$INSTALL_ROOT"
    printf 'backup=%s/install-root\n' "$BACKUP_DIR"
    printf 'action=sync-install-root\n'
  } >> "$BACKUP_DIR/manifest.env"
fi

zish_sync_install_tree

tmp_zshrc="${ZSHRC}.zish.tmp"
if [ -f "$ZSHRC" ]; then
  awk '
    BEGIN { skipping = 0 }
    /^# >>> zish managed block >>>$/ { skipping = 1; next }
    /^# <<< zish managed block <<<$/{ skipping = 0; next }
    skipping == 0 { print }
  ' "$ZSHRC" > "$tmp_zshrc"
else
  : > "$tmp_zshrc"
fi

if grep -Eq '^# Syntax highlighting should be last$|zsh-syntax-highlighting' "$tmp_zshrc"; then
  tmp_block="${tmp_zshrc}.block"
  printf '%s\n' "$MANAGED_BLOCK" > "$tmp_block"
  awk -v block_file="$tmp_block" '
    BEGIN { inserted = 0 }
    inserted == 0 && (/^# Syntax highlighting should be last$/ || /zsh-syntax-highlighting/) {
      while ((getline block_line < block_file) > 0) {
        print block_line
      }
      close(block_file)
      print ""
      inserted = 1
    }
    { print }
  ' "$tmp_zshrc" > "${tmp_zshrc}.new"
  rm -f "$tmp_block"
else
  {
    cat "$tmp_zshrc"
    printf '\n%s\n' "$MANAGED_BLOCK"
  } > "${tmp_zshrc}.new"
fi
mv "${tmp_zshrc}.new" "$ZSHRC"
rm -f "$tmp_zshrc"

if command -v zsh >/dev/null 2>&1; then
  zsh -n "$INSTALL_ROOT/config/init.zsh" "$INSTALL_ROOT/config/starship.zsh" "$INSTALL_ROOT/config/tools.zsh" "$INSTALL_ROOT/config/terminal.zsh" "$INSTALL_ROOT/config/plugins.zsh"
fi

if command -v starship >/dev/null 2>&1; then
  TERM=xterm-256color STARSHIP_CONFIG="$INSTALL_ROOT/themes/blue-owl-starship/starship.toml" starship print-config >/dev/null
fi

case "$LOGIN_SHELL_ACTION" in
  change|change-after-install)
    if LOGIN_SHELL_TARGET=$(zish_login_zsh_path); then
      if ! zish_shell_is_listed "$LOGIN_SHELL_TARGET"; then
        printf 'Cannot change login shell to %s because it is not listed in /etc/shells.\n' "$LOGIN_SHELL_TARGET" >&2
        printf 'Add it to /etc/shells first.\n' >&2
        zish_print_login_shell_manual_step "$LOGIN_SHELL_TARGET" "$LOGIN_SHELL_USER"
        exit 1
      elif chsh -s "$LOGIN_SHELL_TARGET" "$LOGIN_SHELL_USER"; then
        LOGIN_SHELL_ACTION=changed
      else
        LOGIN_SHELL_ACTION=manual
        LOGIN_SHELL_ERROR="chsh exited without changing the login shell"
        printf 'Zish installed, but the login shell was not changed automatically.\n' >&2
        zish_print_login_shell_manual_step "$LOGIN_SHELL_TARGET" "$LOGIN_SHELL_USER"
      fi
    else
      printf 'Zish installed, but no usable zsh path was found for the login shell change.\n' >&2
      exit 1
    fi
    ;;
esac

case "$LOGIN_SHELL_ACTION" in
  changed|manual)
    mkdir -p "$BACKUP_DIR"
    {
      printf 'timestamp=%s\n' "$STAMP"
      printf 'source=%s\n' "$SOURCE_ROOT"
      printf 'user=%s\n' "$LOGIN_SHELL_USER"
      printf 'previous_shell=%s\n' "$LOGIN_SHELL_BEFORE"
      printf 'new_shell=%s\n' "$LOGIN_SHELL_TARGET"
      if [ "$LOGIN_SHELL_ACTION" = changed ]; then
        printf 'action=change-login-shell\n'
      else
        printf 'action=change-login-shell-manual\n'
        printf 'error=%s\n' "$LOGIN_SHELL_ERROR"
      fi
    } >> "$BACKUP_DIR/manifest.env"
    ;;
esac

printf 'Zish setup complete.\n'
if [ "$LOGIN_SHELL_ACTION" = manual ] && [ -n "$LOGIN_SHELL_TARGET" ]; then
  printf 'Login shell still needs manual change: chsh -s %s %s\n' "$LOGIN_SHELL_TARGET" "$LOGIN_SHELL_USER"
fi
