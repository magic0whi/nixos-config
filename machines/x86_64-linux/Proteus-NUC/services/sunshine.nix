{
  config,
  lib,
  const,
  pkgs,
  ...
}:
let
  sunshine_port = config.services.sunshine.settings.port;
  s_https = (sunshine_port - 5); # Default: 47984 HTTPS
in
{
  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "sunshine" ];
        AAAA = [ "sunshine" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  networking.firewall = {
    allowedTCPPorts = [
      s_https # Default: 47984 HTTPS
      sunshine_port # Default: 47989 HTTP
      (sunshine_port + 21) # Default: 48010 TCP
    ];
    allowedUDPPorts = [
      (sunshine_port + 9) # Default: 47998 UDP
      (sunshine_port + 10) # Default: 47999 UDP
      (sunshine_port + 11) # Default: 48000 UDP
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
  # Wake up screens (on Niri)
  systemd.user.services.sunshine-wake-monitor = {
    description = "Monitor Sunshine TCP connections and wake monitors";
    after = [ "niri-session.target" ];
    wantedBy = [ "niri-session.target" ];
    serviceConfig.Restart = "on-failure";
    script = ''
      ${config.security.wrapperDir}/conntrack -E -e new -p tcp --dport ${toString s_https} | \
      while read line; do
        echo "New Sunshine connection detected, waking up the monitors"
        ${lib.getExe pkgs.niri} msg action power-on-monitors
        sleep 5
      done
    '';
  };
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    settings = {
      adapter_name =
        if config.home-manager.users.${const.username}.hardware.nvidia.sync then
          "/dev/dri/${const.dgpu_sym_name}"
        else
          "/dev/dri/${const.igpu_sym_name}";
      origin_web_ui_allowed = "pc";
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    # For sunshine-webui
    serversTransports.ignorecert.insecureSkipVerify = true;
    routers.sunshine-webui = {
      rule = "Host(`sunshine.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "sunshine-webui";
      tls = { };
    };
    services.sunshine-webui.loadBalancer = {
      serversTransport = "ignorecert";
      servers = [ { url = "https://127.0.0.1:${toString (sunshine_port + 1)}"; } ];
    };
  };
}
