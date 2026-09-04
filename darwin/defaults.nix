{ user, ... }:

# The macOS preferences worth carrying to a new machine. Each one is a
# `defaults write` that nix-darwin applies on activation.
{
  # nix-darwin writes twenty preference domains and restarts exactly one
  # process, the Dock, and only when a dock.* option is declared. Everything
  # else keeps whatever the owning agent read at login, so on a machine that
  # stays up for weeks a setting reaches the disk and never takes effect.
  #
  # activateSettings asks the running apps to re-read; it does not restart
  # them, so a preference whose owner ignores the notification still needs a
  # logout. It has to run inside the user's GUI session -- activation is root
  # now -- through the same wrapper nix-darwin uses for every `defaults write`.
  system.activationScripts.postActivation.text = ''
    echo >&2 "reloading preferences..."
    launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
  '';

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
}
