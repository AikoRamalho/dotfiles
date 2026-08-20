# dotfiles

Configuration for the tools in my setup (macOS, Apple Silicon), managed with
[home-manager](https://github.com/nix-community/home-manager).

## Layout

`home/` mirrors `$HOME`. Every file under `home/.config/` is linked to the same
path under `~/.config`, so the tree *is* the declaration -- nothing is listed
twice, and adding a file is enough to have it linked.

```
dotfiles/
├── flake.nix          # inputs: nixpkgs, nix-darwin, home-manager, nix-homebrew
├── flake.lock         # pinned input revisions
├── bootstrap.sh       # first run: Nix, ~/.dotfiles, user, switch
├── configuration.nix  # macOS defaults and the Homebrew lists
├── home.nix           # the package lists; the links come from the tree
└── home/
    └── .config/
        ├── git/
        │   └── config
        ├── mise/
        │   └── config.toml
        ├── wezterm/
        │   └── wezterm.lua
        └── zsh/
            └── .zshrc
```

Two of these would historically have lived loose in `$HOME`, and both have a
native way out of it, set in `configuration.nix`:

- **git** already reads `$XDG_CONFIG_HOME/git/config`, so the file is named
  `config` and lands at `~/.config/git/config`. No `~/.gitconfig`.
- **zsh** reads `$ZDOTDIR/.zshrc`, and `environment.variables.ZDOTDIR` points at
  `~/.config/zsh`. No `~/.zshrc`.

Linking is per file, never per directory, so the repository never takes over a
directory that also holds state a tool generates for itself.

### Symlinks point at the working tree

The links use `mkOutOfStoreSymlink`, so `~/.config/zsh/.zshrc` points straight
at the file in this repository rather than at a read-only copy in the Nix store.
Editing it takes effect immediately, with no rebuild -- which is the point of
keeping these configs as plain files instead of generating them from Nix.

The trade-off is that the linked files are not pinned by the flake: what lands
in the home directory is whatever the working tree holds right now.

The one path `home.nix` hardcodes is `~/.dotfiles`, which `bootstrap.sh` points
at wherever the clone actually lives. The repository itself can sit anywhere.

## Install

```sh
git clone git@github.com:<user>/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` does four things, each one skipped if it is already true:

1. installs Determinate Nix
2. links the clone to `~/.dotfiles`
3. rewrites the `user` in `flake.nix` to match the one running it, after asking
4. builds the system unprivileged, then activates it with `sudo`
5. installs the tools the mise config declares

Later rebuilds are one command:

```sh
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/.dotfiles#mac
```

The absolute path is not decoration. `sudo` resets `PATH`, and nix-darwin
publishes its own through `/etc/zshenv`, which `sudo` never reads -- so plain
`sudo darwin-rebuild` fails with `command not found`.

`nix build ~/.dotfiles#darwinConfigurations.mac.system` evaluates and builds
without activating anything -- the equivalent of a dry run.

Files already sitting at a managed path are renamed to `<name>.backup` rather
than aborting the run. That comes from `home-manager.backupFileExtension` in
`flake.nix` -- the `-b` flag belongs to standalone home-manager and does not
exist on `darwin-rebuild`.

Note that a flake only sees files tracked by Git: a new file has to be at least
`git add`ed before a rebuild can see it.

A rebuild does not install the tools the mise config declares; `bootstrap.sh`
runs `mise install` for that, and so should you after adding one.

## Where a tool belongs

Four places a tool can live, and picking the right one is the whole job:

| Layer | For | Pinned by |
| --- | --- | --- |
| `home.packages` in `home.nix` | everything, by default | `flake.lock` |
| `pkgs.unstable.*` in `home.nix` | the few tools where a release behind costs something | `flake.lock` |
| `home/.config/mise/config.toml` | language runtimes and project-scoped tools | the project's own `.mise.toml` |
| `homebrew` in `configuration.nix` | GUI casks and fonts, and whatever nixpkgs does not carry | nothing |

Two rules decide the layer, in this order:

1. **If two of your projects could want different versions, it goes to mise.**
   Only mise has a per-project escape hatch — a `.mise.toml` in the repository
   overrides the global entry. nixpkgs and Homebrew declare one version and that
   is the only one available.
2. **Otherwise nixpkgs, and Homebrew only as an exception** — a GUI cask or
   font, something missing from nixpkgs on `aarch64-darwin`, or something with
   no darwin binary cache. Homebrew is the one layer with no lock: `brew "jq"`
   does not name a version, it names whatever exists on the day you rebuild.

Being a release behind is not a reason to fall back to Homebrew. The
`nixpkgs-unstable` input exists for that: its revision is locked too, so
`pkgs.unstable.neovim` is as reproducible as anything else and moves only when
`nix flake update` says so.

Go is the exception worth knowing: `GOTOOLCHAIN=auto` already resolves the
version from each `go.mod`, so one pinned toolchain in `home.packages` is
enough.

`homebrew.onActivation.cleanup = "zap"` makes those lists authoritative —
anything installed by hand is uninstalled on the next rebuild.

## What is here

| Tool | File | Notes |
| --- | --- | --- |
| zsh | `home/.config/zsh/.zshrc` | Oh My Zsh + powerlevel10k, mise, zoxide, fzf, atuin and aliases |
| git | `home/.config/git/config` | delta as pager and diff filter |
| mise | `home/.config/mise/config.toml` | global tool versions; a project's own `.mise.toml` wins |
| WezTerm | `home/.config/wezterm/wezterm.lua` | rose-pine-moon theme; dims unfocused windows |

## Dependencies

Everything the `.zshrc` expects on `PATH` is declared — in `home.packages`, in
the `homebrew` lists or in the mise config — so a rebuild installs it all.

The zsh prompt and plugins come from nixpkgs like everything else --
powerlevel10k, `fzf-tab`, `zsh-autosuggestions`, `zsh-syntax-highlighting`,
`zsh-completions` and `zsh-history-substring-search`. The `.zshrc` sources them
through `NIX_PROFILES` rather than by store path, so no hashes leak into the
file.

There is no Oh My Zsh. It contributed completions that `/etc/zshenv` already
puts on `fpath` for every profile, and aliases the `.zshrc` defines itself; what
it cost was a git clone of unpinned upstream HEADs on every new machine.

## Kept out of the repository

`~/.p10k.zsh` (generated by `p10k configure`) is not versioned here.
