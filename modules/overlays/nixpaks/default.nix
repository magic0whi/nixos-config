# Add nixpaked apps into nixpkgs
nixpak: _final: prev:
let
  mk_nixpak =
    pkgs: path:
    pkgs.callPackage path {
      mkNixPak = nixpak.lib.nixpak {
        inherit (pkgs) lib;
        inherit pkgs;
      };
    };
in
{
  nixpaks = {
    # Self-contained packages: wrapped launcher + desktop entry + icons.
    qq = mk_nixpak prev ./qq.nix;
    wechat = mk_nixpak prev ./wechat.nix;
  };
}
