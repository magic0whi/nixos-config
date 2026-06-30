{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  networking.firewall = {
    allowedTCPPorts = [
      443
      8443
    ];
    allowedUDPPorts = [ 8443 ]; # QUIC
  };

  sops.secrets =
    let
      sopsFile = "${const.secretsDir}/common.sops.yaml";
      restartUnits = [ "sing-box.service" ];
    in
    {
      sb_nodes_anytls_password = { inherit sopsFile restartUnits; };
      sb_nodes_reality_priv_key = { inherit sopsFile restartUnits; };
      sb_nodes_reality_short_id = { inherit sopsFile restartUnits; };
      sb_nodes_server_name = { inherit sopsFile restartUnits; };
    };
  services.sing-box = {
    enable = true;
    package = pkgs.sing-box-beta;
    settings = {
      log = {
        level = "warn";
        timestamp = false;
      };
      # dns.servers = lib.singleton {
      #   tag = "Default";
      #   type = "tls";
      #   server = "8.8.8.8";
      # };
      inbounds = lib.singleton {
        type = "anytls";
        listen = "::";
        listen_port = 443;
        users = lib.singleton {
          name = "proteus";
          password._secret = config.sops.secrets.sb_nodes_anytls_password.path;
        };
        tls = {
          enabled = true;
          server_name._secret = config.sops.secrets.sb_nodes_server_name.path;
          reality = {
            enabled = true;
            handshake = {
              server._secret = config.sops.secrets.sb_nodes_server_name.path;
              server_port = 443;
            };
            private_key._secret = config.sops.secrets.sb_nodes_reality_priv_key.path;
            short_id._secret = config.sops.secrets.sb_nodes_reality_short_id.path;
          };
        };
      };
      outbounds = lib.singleton {
        tag = "Direct";
        type = "direct";
      };
      route = {
        rules = [
          {
            action = "reject";
            method = "drop";
            invert = true;
            rule_set_ip_cidr_match_source = true; # Make ip_cidr in rule-sets match the source IP.
            rule_set = [
              "asn-china-mobile-as56046"
              "asn-china-telecom-as4134"
              "asn-china-telecom-as140292"
              "asn-china-telecom-as4812"
            ];
          }
          # Drop all IPv6 requests
          {
            action = "reject";
            no_drop = true;
            ip_version = 6;
            # ip_cidr = [ "::/0" ];
          }
        ];
        rule_set =
          let
            inherit (const.sb.ruleSetCfg) urlPrefix;
            defaultCfg = const.sb.ruleSetCfg.defaultCfg // {
              download_detour = "Direct";
            };
          in
          map (rule_set: defaultCfg // rule_set) [
            {
              tag = "asn-china-mobile-as56046";
              url = "${urlPrefix}/asn/AS56046.srs";
            }
            {
              tag = "asn-china-telecom-as4134";
              url = "${urlPrefix}/asn/AS4134.srs";
            }
            {
              tag = "asn-china-telecom-as140292";
              url = "${urlPrefix}/asn/AS140292.srs";
            }
            {
              tag = "asn-china-telecom-as4812";
              url = "${urlPrefix}/asn/AS4812.srs";
            }
          ];
      };
    };
  };

  # NOTE: tried tcp passthrough, sing-box don't support proxy protocol so it don't know the real source IP from traefik
  # also tried dynamicConfigFile, will ignore all the existing settings under dynamicConfigOptions
  services.traefik = lib.mkIf config.services.traefik.enable {
    # staticConfigOptions.log.level = "DEBUG";
    staticConfigOptions.entryPoints.websecure.address = ":8443";
  };
}
