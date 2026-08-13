#!/bin/sh
# Install lasyd from a checkout or directly via curl | sh.
set -eu

REPO_URL=${LASYD_REPO_URL:-https://github.com/lakubuDavid/lasyd.git}
INSTALL_ROOT=${LASYD_HOME:-"$HOME/.local/share/lasyd"}
BIN_DIR=${LASYD_BIN_DIR:-"$HOME/.local/bin"}
SCRIPT_DIR=$(CDPATH=; cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR=$SCRIPT_DIR
TEMP_DIR=

if [ ! -f "$SOURCE_DIR/bin/lasyd" ] || [ ! -d "$SOURCE_DIR/lasyd" ]; then
  command -v git >/dev/null 2>&1 || {
    printf '%s\n' 'error: git is required when installing from a remote script' >&2
    exit 1
  }
  TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/lasyd-install.XXXXXX")
  trap 'rm -rf "$TEMP_DIR"' EXIT HUP INT TERM
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo"
  SOURCE_DIR=$TEMP_DIR/repo
fi

[ -f "$SOURCE_DIR/bin/lasyd" ] || { printf '%s\n' 'error: lasyd launcher not found' >&2; exit 1; }
[ -d "$SOURCE_DIR/lasyd" ] || { printf '%s\n' 'error: lasyd runtime directory not found' >&2; exit 1; }

mkdir -p "$INSTALL_ROOT" "$BIN_DIR"
cp -R "$SOURCE_DIR/." "$INSTALL_ROOT/"
ln -sfn "$INSTALL_ROOT/bin/lasyd" "$BIN_DIR/lasyd"
chmod 755 "$INSTALL_ROOT/bin/lasyd"

printf '%s\n' "installed lasyd: $BIN_DIR/lasyd -> $INSTALL_ROOT/bin/lasyd"
printf '%s\n' 'Add the launcher directory to PATH if needed:'
printf '%s\n' "  export PATH=\"$BIN_DIR:\$PATH\""
