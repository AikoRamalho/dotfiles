{ user, ... }:

{
  imports = [
    ./home/links.nix
    ./home/packages.nix
    ./home/shell.nix
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
