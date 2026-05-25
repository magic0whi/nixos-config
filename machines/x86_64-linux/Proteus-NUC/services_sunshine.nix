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
      sunshine_port = config.services.sunshine.settings.port;
      s_https = toString (sunshine_port - 5); # Default: 47984 HTTPS
      s_http = toString sunshine_port; # Default: 47989 HTTP
      s_video = toString (sunshine_port + 9); # Default: 47998 UDP
      s_ctrl = toString (sunshine_port + 10); # Default: 47999 UDP
      s_audio = toString (sunshine_port + 11); # Default: 48000 UDP
      s_rtsp = toString (sunshine_port + 21); # Default: 48010 TCP
    in
    {
      allowedTCPPorts = [
        (lib.toInt s_https)
        (lib.toInt s_http)
        (lib.toInt s_rtsp)
      ];
      allowedUDPPorts = [
        (lib.toInt s_video)
        (lib.toInt s_ctrl)
        (lib.toInt s_audio)
      ];
    };
  # Ref: https://github.com/orgs/LizardByte/discussions/439#discussioncomment-15813284
  security.wrappers = lib.mkIf config.services.sunshine.enable {
    conntrack = {
      source = "${pkgs.conntrack-tools}/bin/conntrack";
      capabilities = "cap_net_admin+ep"; # conntrack needs `cap_net_admin` to run as a normal user
      owner = "root";
      group = "root";
    };
  };
  # Adapt for Hyprland
  systemd.user.services =
    lib.mkIf
      (config.services.sunshine.enable && config.home-manager.users.${myvars.username}.wayland.windowManager.hyprland.enable)
      {
        sunshine-wake-monitor = {
          description = "Monitor Sunshine TCP connections and wake monitors";
          after = [ "hyprland-session.target" ];
          wantedBy = [ "hyprland-session.target" ];
          serviceConfig.Restart = "on-failure";
          script = ''
            ${config.security.wrapperDir}/conntrack -E -e new -p tcp --dport ${
              toString (config.services.sunshine.settings.port - 5)
            } | \
            while read line; do
              echo "New Sunshine connection detected, waking up the monitors"
              ${lib.getExe' pkgs.hyprland "hyprctl"} --instance 0 'dispatch dpms on'
              sleep 5
            done
          '';
        };
      };
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    settings = {
      adapter_name =
        if config.home-manager.users.${myvars.username}.wayland.windowManager.hyprland.nvidia_sync then
          "/dev/dri/${myvars.dgpu_sym_name}"
        else
          "/dev/dri/${myvars.igpu_sym_name}";
      origin_web_ui_allowed = "pc";
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    # For sunshine-webui
    serversTransports.ignorecert.insecureSkipVerify = true;
    routers.sunshine-webui = {
      rule = "Host(`sunshine.${myvars.domain}`)";
      entryPoints = [ "websecure" ];
      service = "sunshine-webui";
      tls = { };
    };
    services.sunshine-webui.loadBalancer = {
      serversTransport = "ignorecert";
      servers = [ { url = "https://127.0.0.1:${toString (config.services.sunshine.settings.port + 1)}"; } ];
    };
  };
}
