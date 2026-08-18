#!/usr/bin/env bash
#
# Brings this configuration up on a machine, in four steps:
#
#   1. install Nix, unless it is already there
#   2. link the clone to ~/.dotfiles, the one path home.nix hardcodes
#   3. make the flake's user match whoami
#   4. build and activate the system
#
# Every step checks the state it is about to create, so running it again on a
# machine that is already set up does nothing but confirm that.
#
# Usage:
#   ./bootstrap.sh

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINK="$HOME/.dotfiles"
NIX_BIN="/nix/var/nix/profiles/default/bin"
HOST="mac"

step() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# ─── 1. Nix ───────────────────────────────────────────────────────────
step "Nix"
if command -v nix >/dev/null 2>&1 || [[ -x "$NIX_BIN/nix" ]]; then
  info "already installed"
else
  info "installing with the Determinate Systems installer"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
fi

# The installer sets up the login shells, not the shell running this script.
export PATH="$NIX_BIN:$PATH"
command -v nix >/dev/null 2>&1 || die "nix is still not on PATH; open a new shell and run this again"
info "$(nix --version)"

# ─── 2. ~/.dotfiles ───────────────────────────────────────────────────
step "Linking $LINK"
if [[ "$DIR" == "$LINK" ]]; then
  info "the clone already lives at $LINK"
elif [[ -e "$LINK" && ! -L "$LINK" ]]; then
  die "$LINK exists and is not a symlink; move it aside first"
else
  ln -sfn "$DIR" "$LINK"
  info "$LINK -> $(readlink "$LINK")"
fi

# ─── 3. user ──────────────────────────────────────────────────────────
step "User"
user="$(whoami)"
flake_user="$(sed -n 's/^ *user = "\(.*\)";$/\1/p' "$DIR/flake.nix" | head -1)"
[[ -n "$flake_user" ]] || die "could not read the user from flake.nix"

if [[ "$user" == "$flake_user" ]]; then
  info "flake.nix already targets '$user'"
else
  info "flake.nix targets '$flake_user', but you are '$user'"
  read -r -p "    Rewrite flake.nix to use '$user'? [y/N] " answer
  case "$answer" in
    [yY] | [yY][eE][sS]) ;;
    *) die "left alone; edit the user in flake.nix by hand to continue" ;;
  esac

  sed -i '' "s/^\( *user = \)\".*\";\$/\1\"$user\";/" "$DIR/flake.nix"
  info "flake.nix now targets '$user'"

  # A flake only reads files Git tracks, so an unstaged edit is invisible to
  # the build that follows.
  git -C "$DIR" add flake.nix
fi

# ─── 4. build and activate ────────────────────────────────────────────
step "Building and activating"
if [[ -x /run/current-system/sw/bin/darwin-rebuild ]]; then
  rebuild="/run/current-system/sw/bin/darwin-rebuild"
else
  info "no system generation yet; taking darwin-rebuild from the flake"
  mkdir -p "$DIR/tmp"
  nix build "$LINK#darwinConfigurations.$HOST.system" --out-link "$DIR/tmp/system"
  rebuild="$DIR/tmp/system/sw/bin/darwin-rebuild"
fi

# Built unprivileged above, so root is only needed for the activation itself.
# The absolute path is required: sudo resets PATH and never reads the
# /etc/zshenv where nix-darwin publishes its own.
info "activating as root"
sudo "$rebuild" switch --flake "$LINK#$HOST"

step "Done"
info "open a new shell to pick up the new environment"
info "then run: mise install"
