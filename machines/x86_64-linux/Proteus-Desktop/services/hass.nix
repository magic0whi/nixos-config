{
  config,
  const,
  pkgs,
  mylib,
  ...
}:
{
  sops =
    let
      restartUnits = [ "home-assistant.service" ];
    in
    {
      secrets.hass_oidc_secret = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      };
      templates."hass_secrets.yaml" = {
        inherit restartUnits;
        content = mylib.toYAML { hass_oidc_secret = config.sops.placeholder.hass_oidc_secret; };
      };
    };
  systemd.services.home-assistant = {
    serviceConfig.LoadCredential = "hass_secrets.yaml:${config.sops.templates."hass_secrets.yaml".path}";
    preStart = ''
      ln -sf $CREDENTIALS_DIRECTORY/hass_secrets.yaml ${config.services.home-assistant.configDir}/secrets.yaml
    '';
  };
  hardware.bluetooth.enable = true;
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
      auth_oidc
      xiaomi_miot # Xiaomi Miot Auto (Community)
      # xiaomi_home # Xiaomi Home (Official)
      midea_ac_lan # TODO: add refrigerator
    ];
    config = {
      default_config = { }; # Implicitly enable `mobile_app`
      http = {
        server_port = 8123;
        server_host = [
          "127.0.0.1"
          "::1"
        ];
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
        cors_allowed_origins = [ "https://hass.${const.domain}" ];
      };
      homeassistant = {
        name = "Proteus' Homo";
        unit_system = "metric"; # or "us_customary"
        inherit (const) latitude longitude;
        time_zone = config.time.timeZone;
      };
      logger.default = "info";
      # https://wiki.nixos.org/wiki/Home_Assistant#Automations,_Scenes,_and_Scripts_from_the_UI
      "automation ui" = "!include automations.yaml";
      "script ui" = "!include scripts.yaml";
      auth_oidc = {
        client_id = "hass";
        client_secret = "!secret hass_oidc_secret";
        discovery_url = "https://auth.${const.domain}/.well-known/openid-configuration";
        display_name = "Authelia";
        features = {
          automatic_user_linking = false; # NOTE: It's recommended to only enable this temporarily
          automatic_person_creation = true;
        };
      };
    };
  };
  services.traefik.dynamicConfigOptions.http = {
    routers.home-assistant = {
      rule = "Host(`hass.${const.domain}`)";
      entryPoints = [ "websecure" ];
      service = "home-assistant";
      tls = { };
    };
    services.home-assistant.loadBalancer.servers =
      let
        hass_port = toString config.services.home-assistant.config.http.server_port;
      in
      [
        { url = "http://127.0.0.1:${hass_port}"; }
        { url = "http://[::1]:${hass_port}"; }
      ];
  };
}
