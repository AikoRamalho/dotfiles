# dotfiles

A declarative macOS workstation. One flake describes the machine: system
preferences, the Homebrew inventory, the user's packages, the shell, the prompt,
and the config files of the tools that keep their own. `bootstrap.sh` takes a
fresh Apple Silicon Mac to that state; after that, every change is an edit and
a rebuild.

The repository is the source of truth, and the tooling enforces it. Homebrew
runs with `cleanup = "zap"`, so anything installed by hand is removed on the
next rebuild. Nix packages come from a locked nixpkgs revision. Config files
are symlinked into place from the working tree, so an edit takes effect at once
and a rebuild is only needed when the set of files or packages changes.

## Operating it

First run on a machine:

```sh
git clone git@github.com:<user>/dotfiles.git
cd dotfiles
./bootstrap.sh
```

The script is idempotent. It installs Determinate Nix if missing, links the
clone to `~/.dotfiles`, offers to rewrite the flake's `user` to match `whoami`,
builds the system as your user, activates it with `sudo`, and runs
`mise install`. Re-running it on a configured machine only confirms each step.

Everything after that:

| Task | Command |
| --- | --- |
| Apply a change | `./rebuild.sh` |
| Build without activating | `nix build ~/.dotfiles#darwinConfigurations.mac.system --no-link` |
| Install newly declared mise tools | `mise install` |
| Move every input forward | `nix flake update`, then `./rebuild.sh` |
| Move one input | `nix flake update nixpkgs-unstable`, then `./rebuild.sh` |
| Go back one generation | `./rebuild.sh --rollback` |
| Reclaim disk | `sudo nix-collect-garbage -d` |

`rebuild.sh` refreshes the `~/.dotfiles` link and then runs

```sh
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.dotfiles#mac
```

passing along any arguments it was given. Two of these have a reason behind
their shape:

- **The absolute path to `darwin-rebuild`.** `sudo` resets `PATH`, and
  nix-darwin publishes its own through `/etc/zshenv`, which `sudo` never reads.
  Plain `sudo darwin-rebuild` fails with `command not found`.
- **Garbage collection is manual.** `nix.enable = false` hands the daemon to
  Determinate, and with it the `nix.gc` option. Nothing collects on a schedule,
  so the store grows with every `nix flake update` until you run this.

## Layout

```
flake.nix            inputs and the single darwinConfiguration, "mac"
flake.lock           the pinned revisions; the reproducibility lives here
bootstrap.sh         first run on a machine
rebuild.sh           every run after that
configuration.nix    the machine: platform, primary user, nix.enable = false
darwin/
  defaults.nix       macOS preferences, applied as `defaults write`
  homebrew.nix       the whole Homebrew inventory, casks and one formula
home.nix             the user: identity, stateVersion, EDITOR
home/
  packages.nix       home.packages, stable and unstable
  shell.nix          zsh, starship, fzf, atuin, mise, zoxide
  links.nix          links every file below into ~/.config
  .config/
    git/config
    mise/config.toml
    wezterm/wezterm.lua
```

Every `.nix` file is a module. nix-darwin and home-manager merge them, and each
one sees the same `config`, `pkgs`, `lib` and `user`. The split is only to keep
unrelated things apart. There is no helper layer between the modules and the
options they set.

## How it fits together

Three mechanisms produce what lands in the home directory. Knowing which one
owns a given thing tells you where to change it.

**Generated.** The shell and the prompt are written by home-manager from
`home/shell.nix`. `programs.zsh` assembles `~/.config/zsh/.zshrc` from the
aliases, the plugins and the tool hooks, and writes the one-line `~/.zshenv`
that exports `ZDOTDIR`. `programs.starship` writes the prompt config. Both
reference nixpkgs by store path, so `flake.lock` pins the plugins and the prompt
like any other package. There is no Oh My Zsh: it contributed completions the
tools now ship themselves and aliases the module defines directly, at the cost
of cloning unpinned upstream HEADs on every new machine.

**Linked.** `home/.config` mirrors `~/.config`. `home/links.nix` walks the tree
and links every file to the same path in the home directory, so adding a file
is the whole declaration. The links use `mkOutOfStoreSymlink` and point at the
working tree, not at a store copy: edit the file and the tool sees it, no
rebuild. That is also why these files are not pinned by the flake. Two details
of the walk matter: linking is per file, never per directory, so a tool can keep
its own state next to the linked config; and `.nix` files are skipped, so a
module can sit beside the config it manages.

**Inventoried.** Packages are lists in three places, each with a different
guarantee, described in the next section.

git has no `~/.gitconfig` because it reads `~/.config/git/config` natively. zsh
has no `~/.zshrc` because `ZDOTDIR` moves it. Anything that appends to
`~/.zshrc`, and many installers do, is writing to a file nothing reads.

## Where a tool belongs

| Layer | Declared in | Version comes from | Per-project override |
| --- | --- | --- | --- |
| nixpkgs stable | `home/packages.nix` | `flake.lock` | no |
| nixpkgs unstable | `home/packages.nix`, as `unstable.<name>` | `flake.lock` | no |
| mise | `home/.config/mise/config.toml` | resolved at `mise install` time | yes, `.mise.toml` |
| Homebrew | `darwin/homebrew.nix` | whatever brew has that day | no |

Two questions, in order:

1. **Could two of your projects want different versions?** Then mise. It is
   the only layer with a per-project override, and the global entry is a
   fallback, not a pin. That is also its weakness: `latest` in the global
   config means two machines set up a month apart get different versions, and
   `mise upgrade` moves them silently. Pin a major or minor there when it
   matters.
2. **Otherwise nixpkgs.** Stable by default. Take a package from `unstable`
   when being a release behind costs something: cloud CLIs that chase provider
   APIs, editors whose plugins target the newest release. The unstable input is
   locked too, so this trades nothing in reproducibility. Being behind is never
   a reason to fall back to Homebrew.

Homebrew is the exception layer: GUI apps, fonts, and the rare CLI nixpkgs does
not carry for `aarch64-darwin`. It is the one layer without a lock, and the
inventory is authoritative. `brew install` something to try it; if it earns a
place, declare it, otherwise the next rebuild removes it.

Go is a special case worth knowing. `GOTOOLCHAIN=auto` resolves the toolchain
from each `go.mod`, so one `go` in nixpkgs serves every project. Go tools that
projects pin, such as linters, belong in the project's `go.mod` as `tool`
directives, or in mise.

## Making changes

**A config file for a tool.** Put it under `home/.config/<tool>/` at the path
the tool reads under `~/.config`, `git add` it, rebuild. The link appears; no
module edit.

**A CLI.** Add it to `home/packages.nix` and rebuild. If it is project-scoped,
add it to `mise/config.toml` instead and run `mise install`; a rebuild links the
config but installs nothing from it.

**A GUI app or font.** Add the cask to `darwin/homebrew.nix` and rebuild.
Removing a cask from the list uninstalls it and, because of `zap`, deletes its
data with it. Check what a cask owns before dropping it, and know that
`--rollback` restores the list but not the data.

**A macOS preference.** `darwin/defaults.nix`. Some defaults only apply after
logging out.

**Shell behaviour.** `home/shell.nix`. The `initContent` entries carry explicit
`mkOrder` values because the tool integrations sit at the default order, and
ties would be resolved by module evaluation order, which changes when files
move. zoxide is last on purpose: it replaces `cd` and warns if anything hooks
after it.

**A new input or version bump.** `nix flake update [input]`, rebuild, commit
`flake.lock` with the change it was made for.

## Things that will bite

- **A flake sees only tracked files.** A new file must be at least `git add`ed
  before a rebuild can see it, and until then `links.nix` will not link it
  either. This applies to `.nix` modules too.
- **A rebuild does not run `mise install`.** Until it runs, a tool declared in
  mise resolves to whatever else is on `PATH`, if anything. Worse, mise tries
  to resolve `latest` for each missing tool at every prompt, which is a
  GitHub API call each time.
- **`~/.dotfiles` is the one hardcoded path.** `mkOutOfStoreSymlink` needs a
  path that exists at activation, so `links.nix` cannot derive it from the
  flake. `bootstrap.sh` points the symlink at the real clone, wherever it is.
- **Existing files at managed paths are renamed to `.backup`**, not clobbered
  and not fatal. That is `home-manager.backupFileExtension`; `darwin-rebuild`
  has no `-b` flag.
- **Binaries installed outside the layers still exist.** `~/.local/bin`,
  `~/.cargo/bin`, `~/go/bin` and `~/.opencode/bin` are on `PATH`, deliberately
  after everything declared, so a stray `curl | sh` copy never shadows the
  managed one. Nothing sweeps those directories; that is on you.
- **`nix.enable = false` is not optional here.** Determinate owns the daemon,
  `/etc/nix/nix.conf` and the launchd service. Letting nix-darwin manage them
  too makes the two overwrite each other. This is why `bootstrap.sh` passes
  `--determinate` to the installer.
- **`autoUpdate = true` makes `switch` touch the network.** It refreshes the
  Homebrew index on every run, so two consecutive switches are not guaranteed
  to be identical, and one without connectivity is slower to fail.

## Deliberately not managed

- `~/.zsh_history`. atuin owns command history; that file only feeds the
  autosuggestions and stays where it always was so they do not start empty.
- Login state and credentials: the git credential helper uses the macOS
  keychain, and `aws`, `az` and `kubectl` keep their own profiles under `~`.
- Per-project tool versions. That is what `.mise.toml` and `go.mod` are for.
