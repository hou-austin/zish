#!/bin/sh
set -eu

DRY_RUN=0
YES=0
NO_PACKAGE_INSTALL=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--dry-run] [--yes] [--no-package-install]

Sets up the managed Zish hook and installs/configures supported CLI tools:
zsh, starship, eza, bat, ripgrep, and difftastic.
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

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=lib/setup/packages.sh
. "$REPO_ROOT/lib/setup/packages.sh"

TOOLS="zsh starship eza bat ripgrep difftastic"
MANAGER=$(zish_detect_package_manager)
MISSING_TOOLS=""
PACKAGES=""
UNSUPPORTED_TOOLS=""
FONT_ACTION=none
FONT_NOTE=""
FONT_INSTALL_LABEL=""
FONT_READY=0
TERMINAL_FONT_NAME="MesloLGM Nerd Font Mono"
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

zish_macos_meslo_installed() {
  if command -v brew >/dev/null 2>&1 && brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
    return 0
  fi

  find "$HOME/Library/Fonts" -maxdepth 1 -name 'MesloLGM*NerdFont*.ttf' 2>/dev/null | grep -q .
}

zish_linux_meslo_installed() {
  if command -v fc-match >/dev/null 2>&1; then
    fc-match -f '%{family}\n' 'MesloLGM Nerd Font' 2>/dev/null | grep -qi 'Meslo.*Nerd Font'
  else
    find "${XDG_DATA_HOME:-$HOME/.local/share}/fonts" -name 'MesloLGM*NerdFont*.ttf' 2>/dev/null | grep -q .
  fi
}

zish_install_meslo_linux() {
  tmp_dir=$(mktemp -d)
  font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MesloLGMNerdFont"

  mkdir -p "$font_dir"
  curl -fsSL -o "$tmp_dir/Meslo.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip
  unzip -oq "$tmp_dir/Meslo.zip" -d "$font_dir"

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  fi

  rm -rf "$tmp_dir"
}

zish_configure_apple_terminal_font() {
  osascript <<'APPLESCRIPT'
tell application "Terminal"
  set font name of default settings to "MesloLGM Nerd Font Mono"
  if (count of windows) > 0 then
    set font name of current settings of selected tab of front window to "MesloLGM Nerd Font Mono"
  end if
end tell
APPLESCRIPT
}

case "$(uname -s)" in
  Darwin)
    if zish_macos_meslo_installed; then
      FONT_NOTE="Meslo LGM Nerd Font is installed"
      FONT_READY=1
    elif [ "$NO_PACKAGE_INSTALL" -eq 1 ]; then
      FONT_NOTE="Meslo LGM Nerd Font install skipped by --no-package-install"
    elif [ "$MANAGER" = brew ]; then
      FONT_ACTION=brew-cask
      FONT_INSTALL_LABEL="brew install --cask font-meslo-lg-nerd-font"
      FONT_READY=1
    else
      FONT_NOTE="install Meslo LGM Nerd Font manually and set it in your terminal"
    fi
    ;;
  Linux)
    if zish_is_wsl; then
      FONT_NOTE="WSL detected; install Meslo LGM Nerd Font on the Windows host and set it in Windows Terminal"
    elif zish_linux_meslo_installed; then
      FONT_NOTE="Meslo LGM Nerd Font is installed"
      FONT_READY=1
    elif [ "$NO_PACKAGE_INSTALL" -eq 1 ]; then
      FONT_NOTE="Meslo LGM Nerd Font install skipped by --no-package-install"
    elif command -v curl >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
      FONT_ACTION=linux-user
      FONT_INSTALL_LABEL="download Meslo.zip into ${XDG_DATA_HOME:-$HOME/.local/share}/fonts/MesloLGMNerdFont"
      FONT_READY=1
    else
      FONT_NOTE="install Meslo LGM Nerd Font manually; curl and unzip are required for automatic font install"
    fi
    ;;
  *)
    FONT_NOTE="install Meslo LGM Nerd Font manually and set it in your terminal"
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
      TERMINAL_FONT_NOTE="Apple Terminal font not changed because Meslo LGM Nerd Font is not installed"
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

if [ "$(uname -s)" = Darwin ]; then
  BACKUP_ROOT="$HOME/Library/Application Support/zish/backups"
else
  BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/zish/backups"
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
ZSHRC="$HOME/.zshrc"
MANAGED_BLOCK="# >>> zish managed block >>>
if [ -f \"$REPO_ROOT/config/init.zsh\" ]; then
  source \"$REPO_ROOT/config/init.zsh\"
fi
# <<< zish managed block <<<"

printf 'Zish setup plan\n'
printf '  repo: %s\n' "$REPO_ROOT"
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
  printf '  font: Meslo LGM Nerd Font\n'
  printf '  font install: %s\n' "$FONT_INSTALL_LABEL"
fi
printf '  terminal font: %s\n' "$TERMINAL_FONT_NOTE"

if [ -n "$UNSUPPORTED_TOOLS" ]; then
  printf '  unsupported by detected package manager: %s\n' "$UNSUPPORTED_TOOLS"
fi

if [ -f "$ZSHRC" ]; then
  printf '  backup: %s/.zshrc\n' "$BACKUP_DIR"
else
  printf '  backup: not needed; %s does not exist\n' "$ZSHRC"
fi

if [ -f "$ZSHRC" ] && grep -Eq 'starship[[:space:]]+init[[:space:]]+zsh|starship init zsh' "$ZSHRC"; then
  printf '  note: existing Starship init detected; Zish will set STARSHIP_CONFIG and skip duplicate init\n'
fi

if [ -f "$ZSHRC" ] && grep -Eq '^[[:space:]]*alias[[:space:]]+(ls|ll|la|lt|cat)=' "$ZSHRC"; then
  printf '  note: existing tool aliases detected; Zish aliases load later and may override them\n'
fi

if [ -f "$ZSHRC" ] && grep -Eq '^# Syntax highlighting should be last$|zsh-syntax-highlighting' "$ZSHRC"; then
  printf '  note: zsh-syntax-highlighting detected; managed block will be inserted before it\n'
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
    brew install --cask font-meslo-lg-nerd-font
    ;;
  linux-user)
    zish_install_meslo_linux
    ;;
esac

case "$TERMINAL_FONT_ACTION" in
  apple-terminal)
    zish_configure_apple_terminal_font
    ;;
esac

if [ -f "$ZSHRC" ]; then
  mkdir -p "$BACKUP_DIR"
  cp "$ZSHRC" "$BACKUP_DIR/.zshrc"
  {
    printf 'timestamp=%s\n' "$STAMP"
    printf 'repo=%s\n' "$REPO_ROOT"
    printf 'path=%s\n' "$ZSHRC"
    printf 'backup=%s/.zshrc\n' "$BACKUP_DIR"
    printf 'action=update-managed-zshrc-block\n'
  } > "$BACKUP_DIR/manifest.env"
fi

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
  zsh -n "$REPO_ROOT/config/init.zsh" "$REPO_ROOT/config/starship.zsh" "$REPO_ROOT/config/tools.zsh" "$REPO_ROOT/config/terminal.zsh"
fi

if command -v starship >/dev/null 2>&1; then
  TERM=xterm-256color STARSHIP_CONFIG="$REPO_ROOT/themes/blue-owl-starship/starship.toml" starship print-config >/dev/null
fi

printf 'Zish setup complete.\n'
