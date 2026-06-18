{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  networking.firewall =
    let
      hm_cfg = config.home-manager.users.${myvars.username} or { };
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
      # sing-box
      (lib.mkIf config.services.sing-box.enable {
        trustedInterfaces = [
          ((lib.findFirst (inbound: inbound.type == "tun") { } (config.services.sing-box.settings.inbounds or [ ])).interface_name
            or "sing0"
          )
        ];
      })
    ];
}
