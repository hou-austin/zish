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
  printf 'Apply this plan? [y/N] '
  read answer
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
  zsh -n "$REPO_ROOT/config/init.zsh" "$REPO_ROOT/config/starship.zsh" "$REPO_ROOT/config/tools.zsh"
fi

if command -v starship >/dev/null 2>&1; then
  TERM=xterm-256color STARSHIP_CONFIG="$REPO_ROOT/themes/blue-owl-starship/starship.toml" starship print-config >/dev/null
fi

printf 'Zish setup complete.\n'
