# NOTE: Some options are not supported by nix-darwin directly, manually set them:
#   1. To avoid conflicts with neovim, disable ctrl + up/down/left/right to switch spaces in:
#     [System Preferences] -> [Keyboard] -> [Keyboard Shortcuts] -> [Mission Control]
#   2. Disable use Caps Lock as 中/英 switch in:
#     [System Preferences] -> [Keyboard] -> [Input Sources] -> [Edit] -> [Use 中/英 key to switch ] -> [Disable]
{ config, ... }:
{
  system = {
    defaults = {
      ## NOTE: https://github.com/nix-darwin/nix-darwin/issues/1207#issuecomment-2510402916
      # Customize settings that not supported by nix-darwin directly
      CustomUserPreferences = {
        # Incomplete list of macOS `defaults` commands: https://github.com/yannbertrand/macos-defaults
        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
      };
      menuExtraClock.Show24Hour = true;
      menuExtraClock.ShowSeconds = true;
      menuExtraClock.ShowAMPM = false;
      dock = {
        autohide = true;
        show-recents = false; # Do not show recent apps in dock
        mru-spaces = false; # Do not automatically rearrange spaces based on most recent use
        expose-group-apps = true; # Group windows by apps in Mission Control
        # Hot corner action for corners
        # ref: https://github.com/nix-darwin/nix-darwin/blob/44a7d0e687a87b73facfe94fba78d323a6686a90/modules/system/defaults/dock.nix#L308
        wvous-tl-corner = 2; # top-left - Mission Control
        wvous-tr-corner = 4; # top-right - Desktop
        wvous-bl-corner = 3; # bottom-left - Application Windows
        wvous-br-corner = 11; # bottom-right - Launchpad
      };
      trackpad = {
        Clicking = true; # Tap (without vibration feedback) to click, may need restart to take affect
        TrackpadRightClick = true; # Two finger right click
        TrackpadThreeFingerDrag = true; # Three finger drag
      };
      finder = {
        _FXShowPosixPathInTitle = true;
        _FXSortFoldersFirst = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true; # Show hidden files
        FXDefaultSearchScope = "SCcf"; # Search scope to current folder
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv"; # List view
        NewWindowTarget = "Home"; # Change default folder shown to home
        QuitMenuItem = true; # Allow quitting of the Finder
        ShowMountedServersOnDesktop = true;
        ShowPathbar = true; # Show path breadcrumbs in info bar
        ShowStatusBar = true; # show status bar
      };
      NSGlobalDomain = {
        AppleICUForce24HourTime = true; # Use 24-hour instead of based on region settings.
        # Configures the keyboard control behavior. Mode 3 enables full keyboard control
        AppleKeyboardUIMode = 3;
        NSAutomaticQuoteSubstitutionEnabled = false; # Disable auto quote substitution
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true; # Remap caps lock to escape, useful for vim users
      userKeyMapping = [
        # Remap escape to caps lock
        {
          HIDKeyboardModifierMappingSrc = 30064771113;
          HIDKeyboardModifierMappingDst = 30064771129;
        }
      ];
    };
  };
  # https://github.com/nix-darwin/nix-darwin/issues/905#issuecomment-3691729456
  launchd.user.agents.keyboard-remap.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/hidutil"
      "property"
      "--set"
      ''{"UserKeyMapping":${builtins.toJSON config.system.keyboard.userKeyMapping}}''
    ];
    RunAtLoad = true;
  };
}
