{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  # zsh reads $ZDOTDIR/.zshrc when ZDOTDIR is set, and git reads
  # $XDG_CONFIG_HOME/git/config natively. Pointing ZDOTDIR at ~/.config/zsh
  # is what lets both configs live where every other tool keeps its own,
  # so home/.config can mirror ~/.config with no exceptions to carve out.
  environment.variables.ZDOTDIR = "$HOME/.config/zsh";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    # Takes over the Homebrew already installed at /opt/homebrew: the
    # repositories are replaced by the pinned brew-src input, while the
    # installed formulae and casks are kept. Without this, activation
    # stops rather than touching an existing installation.
    autoMigrate = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    taps = [ ];
    brews = [
      "herdr"
    ];
    casks = [
      "claude-code"
      "docker-desktop"
      "font-hack-nerd-font"
      "raycast"
      "wezterm"
    ];
  };
}