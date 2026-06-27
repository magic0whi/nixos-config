# Custom options as global variables
# TODO: add an assert to prevent host from add other host's config
args@{ config, lib, ... }:
let
  isGlobal = args.isGlobal or false;
  subdomainsCfg = hostname: _nicCfg: {
    options = {
      A = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "List of subdomains that should resolve to this interface's IPv4 address.";
      };
      AAAA = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "List of subdomains that should resolve to this interface's IPv6 address.";
      };
      # NOTE: CNAME is problematic when specify at NIC level, and it will prevent other hosts share the same subname since
      # it only allows one target, so it's better define A/AAAA directly
    };
    config = lib.mkIf (!isGlobal && _nicCfg.config.regHost) (
      lib.mkMerge [
        (lib.mkIf (_nicCfg.config.ipv4 != null) { A = [ hostname ]; })
        (lib.mkIf (_nicCfg.config.ipv6 != null) { AAAA = [ hostname ]; })
      ]
    );
  };

  nicCfg =
    hostname:
    _nicCfg@{ name, config, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Predictable NIC name";
        };

        ipv4 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "The IPv4 address of this NIC";
        };
        ipv4NoCidr = lib.mkOption {
          type = with lib.types; nullOr str;
          readOnly = !isGlobal;
          default = if config.ipv4 != null then builtins.head (lib.strings.splitString "/" config.ipv4) else null;
        };

        ipv6 = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          description = "The IPv6 address of this NIC";
        };
        ipv6NoCidr = lib.mkOption {
          type = with lib.types; nullOr str;
          readOnly = !isGlobal;
          default = if config.ipv6 != null then builtins.head (lib.strings.splitString "/" config.ipv6) else null;
        };

        regHost = lib.mkEnableOption "Whether add TODO to the subdomains A/AAAA records";

        subdomains = lib.mkOption {
          type = lib.types.submodule (subdomainsCfg hostname _nicCfg);
          default = { };
          description = ''
            Additional subdomain records (A, AAAA, CNAME) attached to this network interface.
          '';
        };
      };
    };
in
{
  options = {
    vars.hostAddrs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            freeformType = with lib.types; attrsOf (submodule (nicCfg name));
          }
        )
      );
      example = {
        Proteus-MBP14M4P = {
          tailscale = {
            ipv4 = "100.95.17.39/10";
            ipv6 = "fd7a:115c:a1e0::783a:1127/48";
          };
          easytier = {
            regHost = true;
            ipv4 = "10.0.0.4/24";
            ipv6 = "fdfe:dcba:9877::4/64";
          };
        };
        Proteus-NUC =
          let
            subs = [ "immich" ];
          in
          {
            tailscale = {
              ipv4 = "100.64.161.20/10";
              ipv6 = "fd7a:115c:a1e0::cd3a:a114/48";
              subdomains = {
                A = subs;
                AAAA = subs;
              };
            };
            wire.name = "enp46s0";
          };
      };
      description = "hosts with addresses and subdomains";
    };
    utils.findFirstHostBySubdomain = lib.mkOption {
      type = with lib.types; functionTo (nullOr str);
      default =
        sub:
        lib.findFirst (
          hostname:
          lib.any (nic: builtins.elem sub nic.subdomains.A || builtins.elem sub nic.subdomains.AAAA) (
            builtins.attrValues config.vars.hostAddrs.${hostname}
          )
        ) null (builtins.attrNames config.vars.hostAddrs);
      description = ''
        Function that returns the first hostname containing the specified subdomain, or null if not found.
      '';
      readOnly = true;
    };
  };

  config = {
    vars.hostAddrs =
      let
        regHost = true;
      in
      {
        # ============================================
        # Homelab's Physical Machines (TODO: Try KubeVirt)
        # ============================================
        Proteus-Desktop =
          let
            subdomains =
              let
                sub = [
                  "@"
                  "ns1"
                  "*.s3"
                  "*.s3-pub"
                  "algo-archive"
                  "aria2"
                  "atuin"
                  "auth"
                  "cockpit-desktop"
                  "garage"
                  "git"
                  "hass"
                  "ldap"
                  "monero"
                  "navidrome"
                  "nextcloud"
                  "niks3"
                  "nixos-search"
                  "noogle"
                  "notebook"
                  "opensearch-dashboards"
                  "papra"
                  "plane"
                  "postgresql"
                  "ql"
                  "s3"
                  "s3-pub"
                  "sb-desktop"
                  "syncthing-desktop"
                  "traefik-desktop"
                  "grafana"
                  "prometheus"
                ];
              in
              {
                A = sub;
                AAAA = sub;
              };
          in
          {
            tailscale = {
              inherit regHost;
              ipv4 = "100.89.227.22/10";
              ipv6 = "fd7a:115c:a1e0::1a01:e318/48";
              subdomains = subdomains;
            };
            easytier = {
              inherit regHost;
              ipv4 = "10.0.0.3/24";
              ipv6 = "fdfe:dcba:9877::3/64";
              inherit subdomains;
            };
            wire.name = "enp4s0";
            wireless = {
              name = "wlp0s20u9";
              ipv4 = "192.168.12.1/24";
            };
          };
        # ============================================
        # Other VMs and Physical Machines
        # ============================================
        Proteus-NixOS-0 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.68.75.16";
            ipv6 = "fd7a:115c:a1e0::683a:ad55";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.1";
            ipv6 = "fdfe:dcba:9877::1";
          };
        };
        Proteus-NixOS-1 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.121.95.98";
            ipv6 = "fd7a:115c:a1e0::df3a:5f62";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.5";
            ipv6 = "fdfe:dcba:9877::5";
          };
        };
        Proteus-NixOS-2 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.78.150.50";
            ipv6 = "fd7a:115c:a1e0::823a:9632";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.6";
            ipv6 = "fdfe:dcba:9877::6";
          };
        };
        Proteus-NixOS-3 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.113.250.94";
            ipv6 = "fd7a:115c:a1e0::703a:fa5e";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.7";
            ipv6 = "fdfe:dcba:9877::7";
          };
        };
        Proteus-NixOS-4 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.118.72.118";
            ipv6 = "fd7a:115c:a1e0::e33a:4876";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.8";
            ipv6 = "fdfe:dcba:9877::8";
          };
        };
        Proteus-NixOS-5 = {
          tailscale = {
            inherit regHost;
            ipv4 = "100.90.238.8";
            ipv6 = "fd7a:115c:a1e0::c53a:ee08";
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.9";
            ipv6 = "fdfe:dcba:9877::9";
          };
        };
        Proteus-VF2.wire.ipv4 = "192.168.1.26";
      };
  };
}
