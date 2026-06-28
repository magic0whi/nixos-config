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
  options.vars.hostAddrs = lib.mkOption {
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

  # NOTE: assertions is a nixpkgs option and does not exist on custom modules
  config = lib.optionalAttrs (!isGlobal) (
    let
      hostname = config.networking.hostName;
    in
    {
      assertions = lib.singleton {
        assertion = builtins.all (_hostname: _hostname == hostname) (builtins.attrNames config.vars.hostAddrs);
        message = ''
          Host '${hostname}' is not allowed to configure vars.hostAddrs for other hosts.
          Found configurations for: ${builtins.concatStringsSep ", " (builtins.attrNames config.vars.hostAddrs)}
        '';
      };
    }
  );
  # config.vars.hostAddrs = {
  #   # ============================================
  #   # Homelab's Physical Machines (TODO: Try KubeVirt)
  #   # ============================================

  #   # ============================================
  #   # Other VMs and Physical Machines
  #   # ============================================
  # };
}
