{ lib, ... }:
let
  homebrew_env_script =
    let
      # Homebrew Mirror
      homebrew_mirror_env = {
        # NOTE: This is only useful when you run `brew install` manually! (not via nix-darwin)
        # TUNA mirror
        # HOMEBREW_API_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
        # HOMEBREW_BOTTLE_DOMAIN = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
        # HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
        # HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
        # HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";

        # NJU mirror
        HOMEBREW_API_DOMAIN = "https://mirror.nju.edu.cn/homebrew-bottles/api";
        HOMEBREW_BOTTLE_DOMAIN = "https://mirror.nju.edu.cn/homebrew-bottles";
        HOMEBREW_BREW_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/brew.git";
        HOMEBREW_CORE_GIT_REMOTE = "https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git";
        HOMEBREW_PIP_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
      };
      homebrew_auto_update_env.HOMEBREW_AUTO_UPDATE_SECS = "86400";
    in
    lib.foldlAttrs (
      acc: n: v:
      "${acc}\nexport ${n}=${v}"
    ) "" (homebrew_mirror_env // homebrew_auto_update_env);
in
{
  system.activationScripts.homebrew.text = lib.mkBefore ''
    echo >&2 '# DEBUG:${homebrew_env_script}'
    ${homebrew_env_script}
  '';
  # homebrew need to be installed manually, see https://brew.sh and
  # https://github.com/nix-darwin/nix-darwin/blob/44a7d0e687a87b73facfe94fba78d323a6686a90/modules/homebrew.nix#L541
  environment.etc.zprofile.text = lib.mkAfter ''eval "$(/opt/homebrew/bin/brew shellenv)"'';
  homebrew = {
    enable = true; # TIP: Disable homebrew for fast deploy
    onActivation = {
      # autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo

      # upgrade = true; # Upgrade outdated casks, formulae, and App Store apps

      cleanup = "zap"; # 'zap': Uninstalls all formulae(and related files) not listed in the generated Brewfile
    };
    # Applications to install from Mac App Store using mas. You need to install all these Apps manually first so that
    # your apple account have records for them. otherwise Apple Store will refuse to install them. For details, see
    # https://github.com/mas-cli/mas
    masApps = {
      "Microsoft Excel" = 462058435;
      "Microsoft Outlook" = 985367838;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      OneDrive = 823766827;
      # QQ = 451108668;
      Telegram = 747648890; # Can be managed by home-manager (home-manager's version crash when sending image)
      WeChat = 836500024;
      "WhatsApp Messenger" = 310633997;

      # "GeoGebra Calculator Suite" = 1504416652; # Managed by home-manager
      # LocalSend = 1661733229; # Managed by home-manager
      # sing-box = 6673731168; # Older than sfm in brew cask
    };
    taps = [
      "hashicorp/tap"
      "gcenx/wine" # homebrew-wine - game-porting-toolkit & wine-crossover
    ];
    # formulae, `brew install`
    brews = [
      # "llvm" "lld" "cmake" "ninja" # Poorly with stdlib
    ];
    # `brew install --cask`
    casks = [
      "blender" # 3D modeling, currently in nixpkg it's marked as broken on darwin
      "keepassxc" # gpgme is marked as broken, use casks temporally
      # "sfm" # Standalone client for sing-box, it lacks some features compares to its cli version
      # "clash-verge-rev"
      "thaw" # Powerful menu bar manager, fork of jordanbaird-ice
      "tor-browser"
      "google-chrome"

      # Misc
      # "tencent-lemon" # macOS cleaner
      "neteasemusic" # music
      # "mihomo-party" # transparent proxy tool
      "obs"
      # "ibkr"
      "trader-workstation"
      "thinkorswim"

      # Development
      # "miniforge" # Miniconda's community-driven distribution

      # Setup macfuse: https://github.com/macfuse/macfuse/wiki/Getting-Started
      "macfuse" # for rclone to mount a fuse filesystem

      # "game-porting-toolkit"
      # "gcenx/wine/wine-crossover" # Conflicts with game-porting-toolkit
      # "crossover"
      "steam"
      "mythic" # EPIC game launcher

      ## Creative
      # "sonic-pi" # Music programming
      # "reaper" # Audio editor, managed by home-manager
      "inkscape" # Vector graphics, currently broken in nixpkgs
      "gimp" # As of 11/6/2025, currently not supported on nixpkgs

      "windows-app" # Formerly microsoft-remote-desktop
      "spacedrive"
    ];
  };
}
