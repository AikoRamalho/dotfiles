{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    bottom
    delta
    dust
    duf
    eza
    fd
    gh
    go
    grpcurl
    httpie
    hyperfine
    jq
    k9s
    lazygit
    procs
    ripgrep
    tealdeer
    tmux
    zsh-completions # extra completion functions, picked up through fpath

    # From the unstable input: cloud CLIs chase provider APIs, and Neovim
    # plugins target the newest release, so a release behind costs here.
    unstable.awscli2
    unstable.azure-cli
    unstable.neovim
  ];
}
