#!/usr/bin/env bash
#
# Create this repository's symlinks in the home directory.
#
# home/ does not mirror $HOME: it is only this repository's layout convention,
# with one directory per tool under home/.config/. Every file's destination is
# written down in links.conf, and this script only applies that map.
#
# Usage:
#   ./install.sh            apply the links
#   ./install.sh --dry-run  print what would happen, without changing anything

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$DOTFILES_DIR/home"
MANIFEST="$DOTFILES_DIR/links.conf"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

DRY_RUN=false

log()   { printf '  %s\n' "$*"; }
warn()  { printf '  warn     %s\n' "$*" >&2; }
die()   { printf 'error: %s\n' "$*" >&2; exit 1; }
run()   { if $DRY_RUN; then log "[dry-run] $*"; else "$@"; fi; }
tilde() { printf '%s' "${1/#$HOME/\~}"; }

# Expand ~, $HOME and $XDG_CONFIG_HOME in a destination read from the manifest.
# The substitution is explicit rather than an eval, so the manifest stays data
# and never becomes code.
expand_target() {
  local target="$1"
  target="${target/#\~/$HOME}"
  target="${target//\$XDG_CONFIG_HOME/$XDG_CONFIG_HOME}"
  target="${target//\$HOME/$HOME}"
  printf '%s' "$target"
}

link_file() {
  local source="$1" target="$2"

  # Already points at the right place: nothing to do.
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "ok       $(tilde "$target")"
    return
  fi

  # A link into some other path of this repository (an earlier layout): there
  # is nothing worth keeping, just drop it.
  if [[ -L "$target" && "$(readlink "$target")" == "$DOTFILES_DIR"/* ]]; then
    run rm "$target"
    log "stale    $(tilde "$target")"

  # A real file, or a link pointing outside the repository: keep it first.
  elif [[ -e "$target" || -L "$target" ]]; then
    local backup="$BACKUP_DIR/${target#$HOME/}"
    run mkdir -p "$(dirname "$backup")"
    run mv "$target" "$backup"
    log "backup   $(tilde "$target") -> $(tilde "$backup")"
  fi

  run mkdir -p "$(dirname "$target")"
  run ln -s "$source" "$target"
  log "link     $(tilde "$target") -> $(tilde "$source")"
}

# Every file under home/ has to appear in the manifest; otherwise a new file
# would be versioned but never linked, and the repository would start lying.
check_orphans() {
  local linked="$1" source found=false
  while IFS= read -r -d '' source; do
    source="${source#$SOURCE_DIR/}"
    if ! grep -qxF "$source" <<<"$linked"; then
      warn "home/$source is missing from links.conf"
      found=true
    fi
  done < <(find "$SOURCE_DIR" -type f -not -name '.DS_Store' -print0)
  $found && return 1 || return 0
}

main() {
  [[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
  [[ -d "$SOURCE_DIR" ]] || die "$SOURCE_DIR not found"
  [[ -f "$MANIFEST" ]]   || die "$MANIFEST not found"

  printf 'dotfiles: %s\n' "$DOTFILES_DIR"
  $DRY_RUN && printf 'dry-run mode: nothing will be changed\n'

  local relative target linked=""
  while read -r relative target _; do
    [[ -z "$relative" || "$relative" == \#* ]] && continue
    [[ -n "$target" ]] || die "manifest line without a destination: $relative"
    [[ -f "$SOURCE_DIR/$relative" ]] || die "home/$relative does not exist"

    link_file "$SOURCE_DIR/$relative" "$(expand_target "$target")"
    linked+="$relative"$'\n'
  done < "$MANIFEST"

  check_orphans "$linked" || true

  printf 'done.\n'
}

main "$@"
