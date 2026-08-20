#!/usr/bin/env bash
#
# Brings this configuration up on a machine:
#
#   1. install Determinate Nix, unless it is already there
#   2. link the clone to ~/.dotfiles, the one path home.nix hardcodes
#   3. make the flake's user match the one running the script
#   4. build and activate the system
#   5. install the mise tools the activated config.toml declares
#
# Every step checks the state it is about to create, so running it again on a
# machine that is already set up does nothing but confirm that.
#
# Usage:
#   ./bootstrap.sh

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
LINK="$HOME/.dotfiles"
NIX_BIN="/nix/var/nix/profiles/default/bin"
HOST="mac"

step() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# ─── 0. platform ──────────────────────────────────────────────────────
[[ "$(uname -s)" == Darwin ]] || die "this configuration is for macOS"
[[ "$(uname -m)" == arm64 ]] || die "this configuration targets Apple Silicon; change nixpkgs.hostPlatform in configuration.nix first"

# ─── 1. Nix ───────────────────────────────────────────────────────────
step "Nix"
if command -v nix >/dev/null 2>&1 || [[ -x "$NIX_BIN/nix" ]]; then
  info "already installed"
else
  # --determinate matters: configuration.nix sets nix.enable = false on the
  # assumption that determinate-nixd owns the daemon and /etc/nix/nix.conf.
  # Upstream Nix from the same installer would leave nobody managing them.
  info "installing Determinate Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
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
user="$(id -un)"
flake_user="$(sed -n 's/^ *user = "\(.*\)";$/\1/p' "$DIR/flake.nix" | head -1)"
[[ -n "$flake_user" ]] || die "could not read the user from flake.nix"

if [[ "$user" == "$flake_user" ]]; then
  info "flake.nix already targets '$user'"
else
  info "flake.nix targets '$flake_user', but you are '$user'"
  read -r -p "    Rewrite flake.nix to use '$user'? [y/N] " answer || answer=""
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
  # No --out-link: an out-link is registered as a GC root and would pin this
  # first system closure forever. The switch below creates the real root.
  info "no system generation yet; taking darwin-rebuild from the flake"
  system="$(nix build "$LINK#darwinConfigurations.$HOST.system" --no-link --print-out-paths)"
  rebuild="$system/sw/bin/darwin-rebuild"
fi

# Built unprivileged above, so root is only needed for the activation itself.
# The absolute path is required: sudo resets PATH and never reads the
# /etc/zshenv where nix-darwin publishes its own.
info "activating as root"
sudo "$rebuild" switch --flake "$LINK#$HOST"

# ─── 5. mise ──────────────────────────────────────────────────────────
step "mise"
profile_bin="/etc/profiles/per-user/$user/bin"
[[ -x "$profile_bin/mise" ]] || die "$profile_bin/mise is missing; did the activation succeed?"
PATH="$profile_bin:$PATH" "$profile_bin/mise" install --yes

step "Done"
info "open a new shell to pick up the new environment"
[[ -f "$HOME/.p10k.zsh" ]] || info "powerlevel10k runs its wizard on the first prompt to create ~/.p10k.zsh"
