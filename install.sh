#!/bin/sh
# Install lasyd from a checkout or directly via curl | sh.
set -eu

REPO_URL=${LASYD_REPO_URL:-https://github.com/lakubuDavid/lasyd.git}
INSTALL_ROOT=${LASYD_HOME:-"$HOME/.local/share/lasyd"}
BIN_DIR=${LASYD_BIN_DIR:-"$HOME/.local/bin"}
SCRIPT_DIR=$(CDPATH=; cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR=$SCRIPT_DIR
TEMP_DIR=

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  CYAN='\033[38;2;116;141;166m'; GREEN='\033[38;2;156;180;204m'; LAVENDER='\033[38;2;211;206;223m'; YELLOW='\033[38;2;242;215;217m'; RESET='\033[0m'
else
  CYAN=; GREEN=; LAVENDER=; YELLOW=; RESET=
fi

printf '%b\n' "${CYAN}========================================${RESET}"
printf '%b\n' "${CYAN}             lasyd installer${RESET}"
printf '%b\n' "${CYAN}========================================${RESET}"
printf '%b\n' "${GREEN}lasyd manages user services on macOS and Linux.${RESET}"
printf '%b\n' 'It generates launchd and systemd units from readable Lua service definitions.'
printf '%b\n' "${LAVENDER}Install launcher:${RESET} $BIN_DIR/lasyd"
printf '%b' "${YELLOW}Continue with installation? [y/N] ${RESET}"

if [ "${LASYD_YES:-}" != "1" ] && [ "${LASYD_YES:-}" != "true" ]; then
  if [ -r /dev/tty ]; then
    read -r answer </dev/tty || answer=
    case "$answer" in y|Y|yes|YES) ;; *) printf '%s\n' 'Installation cancelled.'; exit 0 ;; esac
  else
    printf '%s\n' 'error: no interactive terminal; set LASYD_YES=1 to confirm' >&2
    exit 1
  fi
fi

if [ ! -f "$SOURCE_DIR/bin/lasyd" ] || [ ! -d "$SOURCE_DIR/lasyd" ]; then
  command -v git >/dev/null 2>&1 || { printf '%s\n' 'error: git is required' >&2; exit 1; }
  TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/lasyd-install.XXXXXX")
  trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
  printf '%b\n' "${CYAN}Cloning lasyd repository...${RESET}"
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo"
  SOURCE_DIR=$TEMP_DIR/repo
fi

[ -f "$SOURCE_DIR/bin/lasyd" ] || { printf '%s\n' 'error: lasyd launcher not found' >&2; exit 1; }
[ -d "$SOURCE_DIR/lasyd" ] || { printf '%s\n' 'error: lasyd runtime directory not found' >&2; exit 1; }

mkdir -p "$INSTALL_ROOT" "$BIN_DIR"
cp -R "$SOURCE_DIR/." "$INSTALL_ROOT/"
ln -sfn "$INSTALL_ROOT/bin/lasyd" "$BIN_DIR/lasyd"
chmod 755 "$INSTALL_ROOT/bin/lasyd"

printf '%b\n' "${GREEN}Installed lasyd:${RESET} $BIN_DIR/lasyd -> $INSTALL_ROOT/bin/lasyd"
printf '%b\n' "${YELLOW}Add to PATH if needed:${RESET}"
printf '%s\n' "  export PATH=\"$BIN_DIR:\$PATH\""
