# Add nixpaked apps into nixpkgs
final: prev:
let
  call_package =
    pkgs: path:
    (pkgs.callPackage path {
      mkNixPak = pkgs.nixpak.lib.nixpak {
        inherit (pkgs) lib;
        inherit pkgs;
      };
      safeBind = sloth: realdir: mapdir: [
        (sloth.mkdir (sloth.concat' sloth.appDataDir realdir))
        (sloth.concat' sloth.homeDir mapdir)
      ];
    }).config.script;
in
{
  nixpaks = {
    qq = call_package final ./qq.nix;
    qq-desktop-item = final.callPackage ./qq-desktop-item.nix { };

    wechat-uos = call_package prev ./wechat-uos.nix;
    wechat-uos-desktop-item = final.callPackage ./wechat-uos-desktop-item.nix { };
  };
}
