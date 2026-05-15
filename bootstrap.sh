#!/bin/sh
set -eu

usage() {
  printf '%s\n' \
    'Usage: bootstrap.sh [install args...]' \
    '' \
    'Environment overrides:' \
    '  ZISH_REPO_URL   Git URL to clone. Default: https://github.com/austinhou/zish.git' \
    '  ZISH_BRANCH     Branch to checkout. Default: main' \
    '  ZISH_DIR        Local checkout path. Default: $HOME/.local/share/zish/repo' \
    '' \
    'Examples:' \
    '  curl -fsSL https://raw.githubusercontent.com/austinhou/zish/main/bootstrap.sh | sh' \
    '  curl -fsSL https://raw.githubusercontent.com/austinhou/zish/main/bootstrap.sh | sh -s -- --yes'
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

ZISH_REPO_URL="${ZISH_REPO_URL:-https://github.com/austinhou/zish.git}"
ZISH_BRANCH="${ZISH_BRANCH:-main}"
ZISH_DIR="${ZISH_DIR:-$HOME/.local/share/zish/repo}"

if ! command -v git >/dev/null 2>&1; then
  printf 'zish bootstrap: git is required to clone %s\n' "$ZISH_REPO_URL" >&2
  printf 'Install git first, then rerun this command.\n' >&2
  exit 1
fi

if [ -d "$ZISH_DIR/.git" ]; then
  printf 'zish bootstrap: updating %s\n' "$ZISH_DIR"
  git -C "$ZISH_DIR" fetch --quiet origin "$ZISH_BRANCH"
  git -C "$ZISH_DIR" checkout --quiet "$ZISH_BRANCH"
  git -C "$ZISH_DIR" pull --ff-only --quiet origin "$ZISH_BRANCH"
elif [ -e "$ZISH_DIR" ]; then
  printf 'zish bootstrap: %s exists but is not a Git checkout\n' "$ZISH_DIR" >&2
  printf 'Set ZISH_DIR to another path or move the existing path.\n' >&2
  exit 1
else
  printf 'zish bootstrap: cloning %s into %s\n' "$ZISH_REPO_URL" "$ZISH_DIR"
  mkdir -p "$(dirname "$ZISH_DIR")"
  git clone --quiet --branch "$ZISH_BRANCH" "$ZISH_REPO_URL" "$ZISH_DIR"
fi

if [ ! -f "$ZISH_DIR/install.sh" ]; then
  printf 'zish bootstrap: install.sh is missing in %s\n' "$ZISH_DIR" >&2
  exit 1
fi

exec /bin/sh "$ZISH_DIR/install.sh" "$@"
