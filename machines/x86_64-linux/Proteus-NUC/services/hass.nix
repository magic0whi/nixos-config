{
  config,
  const,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  vars.hostAddrs.${hostname}.easytier.subdomains =
    let
      subs = [ "hass" ];
    in
    {
      A = subs;
      AAAA = subs;
    };
  sops =
    let
      restartUnits = [ "home-assistant.service" ];
    in
    {
      secrets = lib.genAttrs [ "hass_oidc_secret" "hass_latitude" "hass_longitude" ] (_: {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/${hostname}.sops.yaml";
      });
      templates."hass_secrets.yaml" = {
        inherit restartUnits;
        content = mylib.toYAML {
          hass_oidc_secret = config.sops.placeholder.hass_oidc_secret;
          latitude = config.sops.placeholder.hass_latitude;
          longitude = config.sops.placeholder.hass_longitude;
        };
      };
    };
  systemd.services.home-assistant = {
    serviceConfig.LoadCredential = "hass_secrets.yaml:${config.sops.templates."hass_secrets.yaml".path}";
    preStart = ''
      ln -sf $CREDENTIALS_DIRECTORY/hass_secrets.yaml ${config.services.home-assistant.configDir}/secrets.yaml
    '';
  };
  # HA falls into recovery mode (which skips custom components like auth_oidc) if they're missing on the first run
  systemd.tmpfiles.settings."10-home-assistant-ui-includes" =
    let
      inherit (config.services.home-assistant) configDir;
      f = {
        mode = "0644";
        user = "hass";
        group = "hass";
      };
    in
    {
      "${configDir}/automations.yaml" = { inherit f; };
      "${configDir}/scripts.yaml" = { inherit f; };
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
    ];
    config = {
      default_config = { }; # Implicitly enable `mobile_app`
      homeassistant = {
        name = "Proteus' Homo";
        unit_system = "metric"; # or "us_customary"
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        time_zone = config.time.timeZone;
      };
      logger.default = "info";
      # https://wiki.nixos.org/wiki/Home_Assistant#Automations,_Scenes,_and_Scripts_from_the_UI
      "automation ui" = "!include automations.yaml";
      "script ui" = "!include scripts.yaml";
      sensor = lib.singleton {
        platform = "filter";
        name = "NUC CPU Package Temp Smoothed";
        unique_id = "nuc_cpu_package_temp_smoothed";

        entity_id = "sensor.nuc_cpu_package_temp";
        filters = lib.singleton {
          filter = "time_simple_moving_average";
          window_size = "00:05";
          precision = 1;
        };
      };
      command_line = lib.singleton {
        sensor = {
          name = "NUC CPU Package Temp";
          unique_id = "nuc_cpu_package_temp";
          # "Package id 0"; glob over hwmonN since its index isn't stable
          command = "cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input";
          value_template = "{{ (value | int / 1000) | round(1) }}";
          unit_of_measurement = "°C";
          device_class = "temperature";
          state_class = "measurement";
          scan_interval = 30;
        };
      };
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
        hass_port = 8123;
      in
      [
        { url = "http://127.0.0.1:${toString hass_port}"; }
        { url = "http://[::1]:${toString hass_port}"; }
      ];
  };
}
