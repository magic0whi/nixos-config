{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: {
  networking.firewall = let
    sunshine_port = config.services.sunshine.settings.port;
    s_https = toString (sunshine_port - 5); # Default: 47984 HTTPS
    s_http = toString sunshine_port; # Default: 47989 HTTP
    s_video = toString (sunshine_port + 9); # Default: 47998 UDP
    s_ctrl = toString (sunshine_port + 10); # Default: 47999 UDP
    s_audio = toString (sunshine_port + 11); # Default: 48000 UDP
    s_rtsp = toString (sunshine_port + 21); # Default: 48010 TCP
  in {
    allowedTCPPorts = [
      5201 # iperf3
      (lib.toInt (builtins.head config.services.tang.listenStream)) # Tang
      22000 # Syncthing TCP transfers
      53317 # LocalSend (HTTP/TCP)
      # Open Sunshine TCP ports
      (lib.toInt s_https)
      (lib.toInt s_http)
      (lib.toInt s_rtsp)
    ];
    allowedUDPPorts = [
      5201 # iperf3
      21027 # Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
      22000 # Syncthing QUIC transfers
      53317 # LocalSend (Multicast/UDP)
      # Open Sunshine UDP ports
      (lib.toInt s_video)
      (lib.toInt s_ctrl)
      (lib.toInt s_audio)
    ];
  };
  ## BEGIN services_tor.nix
  services.tor = {
    enable = true;
    client.enable = true;
    # openFirewall = true;
    settings = {
      # ExitNodes = "{GB}";
      ExitPolicy = ["accept *:*"];
      AvoidDiskWrites = 1;
      HardwareAccel = 1;
      UseBridges = true;
      ClientTransportPlugin = "snowflake exec ${lib.getExe' pkgs.snowflake "client"} -url https://snowflake-broker.azureedge.net/ -front ajax.aspnetcdn.com -ice stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn -log /tmp/snowflake-client.log";
      Bridge = [
        "snowflake 192.0.2.3:80 2B280B23E1107BB62ABFC40DDCC8824814F80A72 fingerprint=2B280B23E1107BB62ABFC40DDCC8824814F80A72 url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn"
        "snowflake 192.0.2.4:80 8838024498816A039FCBBAB14E6F40A0843051FA fingerprint=8838024498816A039FCBBAB14E6F40A0843051FA url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.net:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn"
      ];
    };
  };
  ## END services_tor.nix
  ## BEGIN services_home_assistant.nix
  services.home-assistant = {
    enable = true;
    # NixOS will automatically fetch the required Python dependencies (like
    # python-miio) and assign Bluetooth capabilities for BLE sensors.
    extraComponents = [
      "default_config"
      "met" # Meteorologisk institute (Met.no)
      "homekit" # xiaomi_miot requires pyhap
    ];
    # Include custom components if specific devices are better supported by the
    # community 'xiaomi_miot' integration.
    customComponents = with pkgs.home-assistant-custom-components; [
      xiaomi_miot # Xiaomi Miot Auto (Community)
      # xiaomi_home # Xiaomi Home (Official)
    ];
    config = {
      default_config = {}; # Implicitly enable `mobile_app`
      http = {
        server_port = 8123;
        server_host = ["127.0.0.1" "::1"];
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
        cors_allowed_origins = ["https://hass.${myvars.domain}"];
      };
      homeassistant = {
        name = "Proteus' Homo";
        unit_system = "metric"; # or "us_customary"
        latitude = config.home-manager.users.${myvars.username}.services.gammastep.settings.manual.lat;
        longitude = config.home-manager.users.${myvars.username}.services.gammastep.settings.manual.lon;
        time_zone = "Asia/Hong_Kong";
      };
      logger.default = "info";
    };
  };
  ## END services_home_assistant.nix
  ## BEGIN services_sunshine.nix
  # Wake monitor when connect
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
    lib.mkIf (
      config.services.sunshine.enable
      && config.home-manager.users.${myvars.username}.wayland.windowManager.hyprland.enable
    ) {
      sunshine-wake-monitor = {
        description = "Monitor Sunshine TCP connections and wake monitors";
        after = ["hyprland-session.target"];
        wantedBy = ["hyprland-session.target"];
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
        if config.home-manager.users.${myvars.username}.wayland.windowManager.hyprland.nvidia_sync
        then "/dev/dri/${myvars.dgpu_sym_name}"
        else "/dev/dri/${myvars.igpu_sym_name}";
      origin_web_ui_allowed = "pc";
    };
  };
  ## END services_sunshine.nix
  ## BEGIN services_caddy.nix
  # TODO: Change to given user caddy `openssh.authorizedKeys.keys` and change the Action for notebook deploy
  # Ensure the web root exists with the correct permissions.
  # Caddy runs as user 'caddy', group 'caddy' by default according to the
  # module. CI script will run as 'proteus', so we make the folder owned by
  # `myvars.username` but give the group (which default to 'caddy') read access.
  systemd.tmpfiles.settings."10-caddy-create-webroot" = let
    root_path = builtins.head (
      builtins.match ''.*root \* ([a-zA-Z0-9/_-]+).*''
      # Get the first attrset under services.caddy.virtualHosts
      (builtins.head (builtins.attrValues config.services.caddy.virtualHosts)).extraConfig
    );
  in {
    ${root_path}.d = {
      mode = "2755";
      user = myvars.username;
      group = config.services.caddy.group;
    };
  };
  services.caddy = {
    enable = true;
    # Caddy doesn't need to bind to public ports (80/443) since Traefik handles
    # that. We can tell Caddy's global config not to attempt ACME/HTTPS bindings.
    globalConfig = ''auto_https off'';
    virtualHosts."http://notebook.${myvars.domain}:8080" = {
      listenAddresses = ["127.0.0.1" "[::1]"];
      extraConfig = ''
        # respond "Hello, world!" # For debug
        root * /srv/www
        file_server
      '';
    };
  };
  ## END services_caddy.nix
}
