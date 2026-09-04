{ user, ... }:

{
  imports = [
    ./user/links.nix
    ./user/packages.nix
    ./user/shell.nix
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";
    stateVersion = "26.05";
    sessionVariables.EDITOR = "code --wait";
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
}
