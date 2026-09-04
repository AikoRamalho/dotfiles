# Working in this repository

Instructions for any agent making changes here. They come from how this
repository has actually been built; follow them rather than the defaults.

## Language

Everything in the repository is **English**: file contents, comments, commit
messages, and variable and attribute names. This holds for files nobody but me
will read. Conversation about the work can be in Portuguese; nothing that lands
in a file or a commit is.

## Commits

- **Commit only when asked.** Finish the work, validate it, leave it in the
  working tree and say it is ready. Do not commit on your own initiative.
- **One logical change per commit, not one file.** Two files that cannot be
  split without leaving a broken tree are one commit. Two unrelated changes in
  one file are two commits.
- **Conventional Commits**, `type(scope): subject`.
- **The subject names the behaviour that changes**, not the file that moves.
  `fix(zsh): initialize zoxide last`, not `update .zshrc`.
- **Short subjects. A body only where the diff does not explain itself**: why
  this approach, what the alternative would have cost, what breaks without it.
  Do not restate the diff in prose.
- **The author is always the user.** No `Co-Authored-By`, no agent attribution anywhere in
  the message.
- **Every commit must leave the tree evaluating.** When a series touches the
  Nix files, check each revision:
  `nix eval "git+file://$PWD?rev=$(git rev-parse <sha>)#darwinConfigurations.mac.system.outPath"`
- **Never `git add -A`.** Stage explicit paths. A conversation export once
  reached a commit that way.

## Validate by running

Claims about behaviour are checked against the machine, not inferred from
documentation. Run the binary, read `--help`, build the derivation, diff the
generated file against the previous one. When a refactor is meant to change
nothing, prove it: compare `home-files` and the generated `.zshrc` before and
after, and explain any difference.

Report what failed as plainly as what worked, including your own mistakes.

## Layout

- `home/.config` **mirrors** `~/.config`. Adding a file there is the whole
  declaration; `home/links.nix` walks the tree and links it.
- **Link per file, never per directory**, so a tool can keep generated state
  next to its config without the repository owning it.
- `links.nix` skips `.nix`, so a module may sit beside the config it manages.
- Every `.nix` file is a plain module merged by nix-darwin or home-manager.
  **Do not build an abstraction over them** — no `mkTool`, no custom options.
  For one host and one user there is no second case to generalise from.
- Split a file when it holds things that change for different reasons, using
  `imports`. Do not split a list into several files.
- Scratch files go in `tmp/`, which is gitignored. Never leave working files in
  the repository root.

## Where a tool goes

One question decides it: **could two of my projects want different versions?**

- **Yes** — mise, in `home/.config/mise/config.toml`. It is the only layer a
  project can override.
- **No** — nixpkgs, in `home/packages.nix`, pinned by `flake.lock`.
- **Homebrew** only for what nixpkgs cannot do on a Mac: GUI casks, fonts, a
  CLI it does not carry for `aarch64-darwin`.

Being a release behind is **not** a reason to reach for Homebrew. The
`nixpkgs-unstable` input exists for that and is locked like everything else.
Homebrew is the one layer without a lock.

## Two things that are easy to get wrong

- A flake sees only files Git tracks. A new file needs `git add` before a
  rebuild — or `links.nix` — can see it.
- `initContent` entries carry explicit `mkOrder` values. Ties at the default
  order are resolved by module evaluation order, which changes when a file
  moves. Do not remove them. If `initContent` grows past roughly fifty lines,
  move the raw zsh into a `.zsh` file in the tree and source it.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project. Do not repeat what the codebase already shows; point to the authoritative file or command instead. Prefer rewriting or pruning existing entries over appending new ones. When updating this file, preserve this bar for all agents and keep entries concise.

