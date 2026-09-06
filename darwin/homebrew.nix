{ user, ... }:

# What Homebrew is allowed to have. cleanup = "zap" makes these lists
# authoritative -- anything installed by hand is uninstalled on the next
# rebuild -- so this is the whole inventory, not a starting point.
{
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
