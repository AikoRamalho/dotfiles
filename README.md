# dotfiles

**A Mac that rebuilds itself from a Git repository.**

Clone, run one script, and a fresh Apple Silicon machine comes up with the
shell, the prompt, the CLIs, the apps, the fonts and the system preferences of
the one you left. Change something later and it is one edit and one command,
on every machine, forever.

## What you get

- **A machine you can describe instead of remember.** Every tool, app and
  preference is declared in this repository. Nothing on the machine exists
  because someone once ran `brew install` and forgot.
- **Drift is impossible by construction.** Homebrew removes anything not
  declared on the next rebuild. Nix packages come from a locked revision. Two
  machines built from the same commit are the same machine.
- **Edits that take effect immediately.** Config files are symlinked from the
  working tree, so a change to `wezterm.lua` is live the moment you save it.
  Rebuild only when you add a file or a package.
- **Rollback in one command.** Every activation is a generation. If a change
  goes wrong, step back to the previous one.
- **A shell that is fast and complete out of the box.** zsh with fzf-tab,
  autosuggestions, syntax highlighting, substring history search, atuin, zoxide
  and a starship prompt that shows the Kubernetes context or the Azure
  subscription only in projects that use them. No Oh My Zsh, no wizards.
- **Per-project tool versions that do not fight the global ones.** Language
  runtimes and project tooling go through mise, so a repository can pin its own
  terraform or node without touching anyone else's.

## Getting started

On a new Mac:

```sh
git clone git@github.com:<user>/dotfiles.git
cd dotfiles
./bootstrap.sh
```

The script installs Nix, wires the clone into place, asks before adapting the
configuration to your username, builds the system, activates it and installs
the mise tools. It is safe to run again; on a machine that is already set up
it just confirms each step.

Open a new terminal and you are done.

## Day to day

**Apply a change.**

```sh
./rebuild.sh
```

**Add a CLI.** Put it in `user/packages.nix` and rebuild.

**Add a config file.** Drop it under `home/.config/<tool>/` at the path the
tool expects in `~/.config`, `git add` it, rebuild. The link appears on its
own; there is nothing to register.

**Add an app or a font.** Add the cask to `darwin/homebrew.nix` and rebuild.

**Add a project tool.** Put it in `home/.config/mise/config.toml` and run
`mise install`.

**Try something without committing to it.** `brew install` it. It works until
the next rebuild, which removes it. If it earned a place by then, declare it.

**Undo the last change.**

```sh
./rebuild.sh --rollback
```

**Move everything forward.** `nix flake update`, rebuild, commit the lock.

## One rule for where things go

Ask: *could two of my projects want different versions of this?*

- **Yes** means mise. It is the only layer a project can override.
- **No** means nixpkgs, pinned by the flake. Homebrew is only for what nixpkgs
  cannot do on a Mac: GUI apps, fonts, the odd CLI it does not carry.

Being a release behind is not a reason to reach for Homebrew. A second,
equally locked `nixpkgs-unstable` input exists for the few tools where the
latest release matters.

## What is inside

```
bootstrap.sh         first run on a machine
rebuild.sh           every run after that
flake.nix            the inputs and the one machine, "mac"
configuration.nix    platform and identity
darwin/              modules for the machine: preferences, Homebrew
home.nix             the user
user/                modules for the user
  packages.nix       the CLIs
  shell.nix          zsh, starship, fzf, atuin, mise, zoxide
  links.nix          links everything under home/ into $HOME
home/                nothing but files that land in $HOME, at the same path
  .claude/           Claude Code settings
  .config/           git, mise, nvim, wezterm
```

Every `.nix` file is a plain module with comments explaining the decisions it
encodes. Start with `user/shell.nix` if you want to see how it feels.

## Design choices, briefly

- **nix-darwin plus home-manager, as one system.** One activation, one
  generation, one rollback, for system and user alike.
- **Release branches, not unstable.** `nixpkgs-26.05-darwin` only advances
  after the darwin builds pass, so a rebuild rarely compiles anything.
- **The tree is the declaration.** `home/.config` mirrors `~/.config` exactly.
  git and zsh, the two tools that traditionally litter `$HOME`, are pointed at
  their XDG paths so the mirror has no exceptions.
- **Generated where generation buys something.** The shell and the prompt are
  produced by home-manager so their plugins come from nixpkgs, pinned like
  everything else. Everything else is a plain file you edit directly.
- **Homebrew is declarative too.** nix-homebrew installs it, and the inventory
  in `darwin/homebrew.nix` is the whole truth of what it holds.

## Good to know

- A rebuild only sees files Git tracks. New files need `git add` first.
- A rebuild links the mise config but does not install from it. Run
  `mise install` after adding a tool there.
- `~/.zshrc` and `~/.gitconfig` do not exist here. Installers that append to
  them are writing to files nothing reads; the real ones live in `~/.config`.
- Removing a cask uninstalls it *and its data*. Rollback restores the list,
  not the data.
- Garbage collection is manual: `sudo nix-collect-garbage -d` when the disk
  asks for it.
- A macOS preference can reach the disk without taking effect. nix-darwin
  writes twenty preference domains and restarts only the Dock; the rest keep
  whatever the owning agent read at login. A rebuild runs `activateSettings` to
  ask them to re-read and then kills `SystemUIServer` and `screencaptureui`,
  which were measured to ignore the notification and to survive a rebuild —
  that is what broke dragging the Cmd-Shift-5 screenshot thumbnail, twice.
  Anything else that holds stale preferences still needs a logout.
- The whole thing assumes one user on one Apple Silicon Mac. That is a
  choice, not a limit of the tools, and it keeps the configuration small.
