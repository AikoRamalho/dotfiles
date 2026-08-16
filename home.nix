{
  config,
  pkgs,
  user,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";

  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/${path}";
in
{
  home = {
    username = user;
    homeDirectory = "/Users/${user}";
    stateVersion = "24.11";

    # Everything the .zshrc expects on PATH. GUI apps and fonts stay in
    # Homebrew, which handles macOS app bundles better than Nix does.
    packages = with pkgs; [
      atuin
      bat
      bottom
      delta
      dust
      duf
      eza
      fd
      fzf
      gh
      go
      grpcurl
      httpie
      hyperfine
      jq
      k9s
      lazygit
      mise
      procs
      ripgrep
      tealdeer
      tmux
      zoxide

      # From the unstable input: cloud CLIs chase provider APIs, and Neovim
      # plugins target the newest release, so a release behind costs here.
      unstable.awscli2
      unstable.azure-cli
      unstable.neovim
    ];
  };

  xdg.configFile = {
    "git/config".source = link ".config/git/config";
    "mise/config.toml".source = link ".config/mise/config.toml";
    "wezterm/wezterm.lua".source = link ".config/wezterm/wezterm.lua";
    "zsh/.zshrc".source = link ".config/zsh/.zshrc";
  };

  programs.home-manager.enable = true;
}
