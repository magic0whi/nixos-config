{
  lib,
  myvars,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.git ]; # Required by flake
  nix = {
    # package = pkgs.nixVersions.latest; # Use latest nix, default is pkgs.nix
    gc = lib.mkMerge [
      {
        automatic = true;
        options = "--delete-older-than 7d";
      }
      (lib.optionalAttrs (!pkgs.stdenv.isDarwin) { dates = "weekly"; })
    ];
    channel.enable = false; # Remove nix-channel related tools & configs, use flakes instead
    # Manual optimise storage: nix-store --optimise
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    optimise.automatic = true; # Add a timer to do optimise periodically
    settings = lib.mkMerge [
      (lib.optionalAttrs (!pkgs.stdenv.isDarwin) { auto-optimise-store = true; }) # Optimise the store after each build
      {
        experimental-features = [
          "nix-command"
          "flakes"
        ]; # Enable flakes globally
        trusted-users = [ myvars.username ];
        # Specify additional substituters via:
        # 1. `nixConfig.substituers` in `flake.nix`
        # 2. command line args `--options substituers http://xxx`
        substituters = [
          # Substituers that will be considered before the official ones (https://cache.nixos.org)
          # cache mirror located in China
          # "https://mirrors.ustc.edu.cn/nix-channels/store" # status: https://mirrors.ustc.edu.cn/status/
          # "https://mirror.sjtu.edu.cn/nix-channels/store" # status: https://mirror.sjtu.edu.cn/
          # Others
          "https://mirrors.sustech.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
        builders-use-substitutes = true;
        sandbox =
          if pkgs.stdenv.isDarwin then
            "relaxed" # KeePassXC
          else
            true;
        # The substituter will be appended to the default substituters when fetching packages.
        extra-substituters = [
          "https://nix-cache.s3-pub.${myvars.domain}"
          "https://hyprland.cachix.org"
          "https://noctalia.cachix.org"
        ];
        extra-trusted-public-keys = [
          "s3.${myvars.domain}-1:IxrRwk4uC5ittHeG9menkuajABnrX9cboEWwZz/m4+E="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      }
    ];
  };
}
