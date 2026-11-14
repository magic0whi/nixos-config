{
  config,
  lib,
  const,
  ...
}:
{
  networking.firewall = {
    allowedTCPPorts = [
      443
      8443
    ];
    allowedUDPPorts = [
      443
      8443
    ]; # QUIC
  };

  sops.secrets =
    let
      restartUnits = [ "sing-box.service" ];
    in
    {
      sb_nodes_anytls_password = { inherit restartUnits; };
      # Shared with ddclient (Cloudflare "Edit zone DNS" token), used for ACME DNS-01
      ddclient_cloudflare_password = {
        inherit restartUnits;
        sopsFile = "${const.secretsDir}/cloud.sops.yaml";
      };
    };
  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "warn";
        timestamp = false;
      };
      experimental.cache_file.enabled = true; # Keep downloaded rule-sets across restarts
      dns = {
        servers = lib.singleton {
          tag = "Default";
          type = "tls";
          server = "8.8.8.8";
        };
        rules = [
          # Refuse China domains outright, without querying upstream
          {
            action = "reject";
            # Keep replying REFUSED instead of switching to drop after 50 triggers in 30s, which would make clients hang
            # until timeout instead of failing fast
            no_drop = true;
            rule_set = [ "geosite-cn" ];
          }
          {
            action = "evaluate";
            server = "Default";
          }
          {
            action = "reject";
            no_drop = true;
            match_response = true;
            rule_set = [ "geoip-cn" ];
          }
          # Return the evaluated response, instead of falling through to `dns.final`, which would query again
          { action = "respond"; }
        ];
      };
      certificate_providers = lib.singleton {
        tag = "ACME";
        type = "acme";
        # Per-node domain, since shared wildcard would hit the Let's Encrypt duplicate certificate rate limit (5 per
        # week) when all nodes request it
        domain = [ "${config.networking.hostName}.${const.cloudDomain}" ];
        data_directory = "/var/lib/sing-box/acme"; # StateDirectory, persisted by impermanence
        inherit (const) email;
        dns01_challenge = {
          provider = "cloudflare";
          api_token._secret = config.sops.secrets.ddclient_cloudflare_password.path;
        };
      };
      inbounds = lib.singleton {
        type = "naive";
        listen = "::";
        listen_port = 443;
        # network = "tcp"; # tcp for HTTP/2, udp for QUIC, leave empty for both
        users = lib.singleton {
          username = "proteus";
          password._secret = config.sops.secrets.sb_nodes_anytls_password.path;
        };
        tls = {
          enabled = true;
          certificate_provider = "ACME";
        };
      };
      outbounds = lib.singleton {
        tag = "Direct";
        type = "direct";
      };
      http_clients = lib.singleton { tag = "Default"; };
      route = {
        # NOTE: domain match and resolve aciton required FakeIP mode on client
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
          # Reject all IPv6 requests
          {
            action = "reject";
            no_drop = true;
            ip_version = 6;
            # ip_cidr = [ "::/0" ];
          }
          # Block China domains
          {
            action = "reject";
            rule_set = [ "geosite-cn" ];
          }
          # Block direct IP requests towards China IPs
          {
            action = "reject";
            rule_set = [ "geoip-cn" ];
          }
          # Clients send domains, no DNS queries, so use resolve action here instead of hijack-dns
          { action = "resolve"; }
        ];
        rule_set =
          let
            inherit (const.sb.ruleSetCfg) urlPrefix defaultCfg;
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
            {
              tag = "geosite-cn";
              url = "${urlPrefix}/geo/geosite/cn.srs";
            }
            {
              tag = "geoip-cn";
              url = "${urlPrefix}/geo/geoip/cn.srs";
            }
          ];
      };
    };
  };

  # NOTE: Tried TCP passthrough, but sing-box doesn't support the PROXY protocol, so it can't see the real source IP
  # behind Traefik. Also tried dynamicConfigFile, but it overrides all existing settings under dynamicConfigOptions
  services.traefik = lib.mkIf config.services.traefik.enable {
    # staticConfigOptions.log.level = "DEBUG";
    staticConfigOptions.entryPoints.websecure.address = ":8443";
  };
}
