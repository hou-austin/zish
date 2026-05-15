# Package manager helpers for Zish setup.

zish_detect_package_manager() {
  if command -v brew >/dev/null 2>&1; then
    printf '%s\n' brew
  elif command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' apt
  elif command -v dnf >/dev/null 2>&1; then
    printf '%s\n' dnf
  elif command -v pacman >/dev/null 2>&1; then
    printf '%s\n' pacman
  elif command -v zypper >/dev/null 2>&1; then
    printf '%s\n' zypper
  elif command -v apk >/dev/null 2>&1; then
    printf '%s\n' apk
  else
    printf '%s\n' none
  fi
}

zish_tool_command_exists() {
  case "$1" in
    bat)
      command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1
      ;;
    ripgrep)
      command -v rg >/dev/null 2>&1
      ;;
    difftastic)
      command -v difft >/dev/null 2>&1
      ;;
    *)
      command -v "$1" >/dev/null 2>&1
      ;;
  esac
}

zish_package_for_tool() {
  manager="$1"
  tool="$2"

  case "$manager:$tool" in
    brew:zsh) printf '%s\n' zsh ;;
    brew:starship) printf '%s\n' starship ;;
    brew:eza) printf '%s\n' eza ;;
    brew:bat) printf '%s\n' bat ;;
    brew:ripgrep) printf '%s\n' ripgrep ;;
    brew:difftastic) printf '%s\n' difftastic ;;

    apt:zsh) printf '%s\n' zsh ;;
    apt:starship) printf '%s\n' starship ;;
    apt:eza) printf '%s\n' eza ;;
    apt:bat) printf '%s\n' bat ;;
    apt:ripgrep) printf '%s\n' ripgrep ;;

    dnf:zsh) printf '%s\n' zsh ;;
    dnf:starship) printf '%s\n' starship ;;
    dnf:eza) printf '%s\n' eza ;;
    dnf:bat) printf '%s\n' bat ;;
    dnf:ripgrep) printf '%s\n' ripgrep ;;
    dnf:difftastic) printf '%s\n' difftastic ;;

    pacman:zsh) printf '%s\n' zsh ;;
    pacman:starship) printf '%s\n' starship ;;
    pacman:eza) printf '%s\n' eza ;;
    pacman:bat) printf '%s\n' bat ;;
    pacman:ripgrep) printf '%s\n' ripgrep ;;
    pacman:difftastic) printf '%s\n' difftastic ;;

    zypper:zsh) printf '%s\n' zsh ;;
    zypper:starship) printf '%s\n' starship ;;
    zypper:eza) printf '%s\n' eza ;;
    zypper:bat) printf '%s\n' bat ;;
    zypper:ripgrep) printf '%s\n' ripgrep ;;
    zypper:difftastic) printf '%s\n' difftastic ;;

    apk:zsh) printf '%s\n' zsh ;;
    apk:starship) printf '%s\n' starship ;;
    apk:eza) printf '%s\n' eza ;;
    apk:bat) printf '%s\n' bat ;;
    apk:ripgrep) printf '%s\n' ripgrep ;;

    *) return 1 ;;
  esac
}

zish_install_command() {
  manager="$1"
  packages="$2"

  case "$manager" in
    brew)
      printf 'brew install %s\n' "$packages"
      ;;
    apt)
      printf 'sudo apt-get update && sudo apt-get install -y %s\n' "$packages"
      ;;
    dnf)
      printf 'sudo dnf install -y %s\n' "$packages"
      ;;
    pacman)
      printf 'sudo pacman -S --needed --noconfirm %s\n' "$packages"
      ;;
    zypper)
      printf 'sudo zypper install -y %s\n' "$packages"
      ;;
    apk)
      printf 'sudo apk add %s\n' "$packages"
      ;;
    *)
      return 1
      ;;
  esac
}
