#!/usr/bin/env bash
#
# Applies the configuration: makes sure ~/.dotfiles points at this clone, then
# hands off to darwin-rebuild. For the first run on a machine use bootstrap.sh.
#
# Usage:
#   ./rebuild.sh              # switch
#   ./rebuild.sh --rollback   # anything after the script name goes to darwin-rebuild

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
LINK="$HOME/.dotfiles"
HOST="mac"
REBUILD="/run/current-system/sw/bin/darwin-rebuild"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# links.nix resolves every config file through ~/.dotfiles, so the link has to
# be right before the activation reads it.
if [[ "$DIR" != "$LINK" ]]; then
  [[ -e "$LINK" && ! -L "$LINK" ]] && die "$LINK exists and is not a symlink; move it aside first"
  ln -sfn "$DIR" "$LINK"
fi

[[ -x "$REBUILD" ]] || die "no system generation yet; run ./bootstrap.sh first"

# The absolute path is required: sudo resets PATH and never reads the
# /etc/zshenv where nix-darwin publishes its own.
exec sudo "$REBUILD" switch --flake "$LINK#$HOST" "$@"
