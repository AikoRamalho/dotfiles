{ config, lib, ... }:

let
  # Where this repository is reachable from. mkOutOfStoreSymlink needs a path
  # that exists at activation time, not a copy in the Nix store, so it cannot be
  # derived from the flake itself. bootstrap.sh points ~/.dotfiles at wherever
  # the clone actually lives, which keeps this one line true on any machine.
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  root = ./.;

  relative = file: lib.removePrefix "${toString root}/" (toString file);

  # home/ mirrors $HOME: every file under it is linked to the same path in the
  # home directory, so the tree is the declaration and nothing is listed twice.
  # Most of it is home/.config, but a tool that keeps its config elsewhere --
  # ~/.claude, say -- needs no special case.
  #
  # Linking is per file, never per directory, so the repository never takes over
  # a directory that also holds state the tool generates for itself. ~/.claude
  # is the clearest example: settings.json is ours, projects/ and history are
  # not.
  #
  # The links point at the working tree rather than at a read-only store copy,
  # so editing a file takes effect without a rebuild.
  linkOf = file: {
    name = relative file;
    value.source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/${relative file}";
  };

  # .nix is skipped: the modules live in this directory, and without the filter
  # they would be linked into $HOME as if they were configuration.
  ignored = file: let name = baseNameOf (toString file); in
    name == ".DS_Store" || lib.hasSuffix ".nix" name;

  tracked = builtins.filter (f: !ignored f) (lib.filesystem.listFilesRecursive root);
in
{
  home.file = builtins.listToAttrs (map linkOf tracked);
}
