{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  networking.firewall =
    let
      hm_cfg = config.home-manager.users.${const.username} or { };
    in
    lib.mkMerge [
      # Localsend
      {
        allowedTCPPorts = lib.mkIf (builtins.elem pkgs.localsend (hm_cfg.home.packages or [ ])) [ 53317 ];
        allowedUDPPorts = lib.mkIf (builtins.elem pkgs.localsend (hm_cfg.home.packages or [ ])) [ 53317 ];
      }

      # Syncthing
      {
        allowedTCPPorts = lib.mkIf (hm_cfg.services.syncthing.enable or false) [ 22000 ];
        # 21027: Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
        allowedUDPPorts = lib.mkIf (hm_cfg.services.syncthing.enable or false) [
          21027
          22000
        ];
      }
    ];
}
