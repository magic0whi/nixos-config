{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.automateBind;

  ## BEGIN Functions (Kept exactly as your original logic)
  rename_attr_to = src_attr: dest_attr: hosts:
    builtins.mapAttrs (_: v: v // {${dest_attr} = v.${src_attr};}) (lib.filterAttrs (_: v: v ? ${src_attr}) hosts);

  # Usage example
  # gen_v4_records "et" {Proteus-Desktop = [{ipv4 = "100.89.227.22";} {ipv4 = "10.0.0.3";}]; Proteus-NUC = [{ipv4 = "100.64.161.20"; } {ipv4 = "10.0.0.2";}];}
  # => ''
  # Proteus-Desktop.et IN A 100.89.227.22
  # Proteus-Desktop.et IN A 10.0.0.3
  # Proteus-NUC.et IN A 100.64.161.20
  # Proteus-NUC.et IN A 10.0.0.2
  # ''
  gen_v4_records = lib.foldlAttrs (acc_1: hostname: ifaces: (lib.concatStrings [
    (lib.optionalString (acc_1 != "") "${acc_1}\n") # Prepend if not first loop
    (lib.foldl (acc_2: iface: (lib.concatStrings [
        (lib.optionalString (acc_2 != "") "${acc_2}\n")
        (
          lib.optionalString (iface.ipv4 != null)
          "${hostname} IN A ${iface.ipv4}"
        )
      ])) ""
      ifaces)
  ])) "";
  gen_v6_records = lib.foldlAttrs (acc_1: hostname: ifaces: (lib.concatStrings [
    (lib.optionalString (acc_1 != "") "${acc_1}\n") # Prepend if not first loop
    (lib.foldl (acc_2: iface: (lib.concatStrings [
        (lib.optionalString (acc_2 != "") "${acc_2}\n")
        (
          lib.optionalString (iface.ipv6 != null)
          "${hostname} IN AAAA ${iface.ipv6}"
        )
      ])) ""
      ifaces)
  ])) "";

  # gen_subdomain_records {Proteus-Desktop = [{ipv4 = "100.89.227.22"; ipv6 = "fd7a:115c:a1e0::1a01:e318"; domains.CNAME = ["garage"];} {ipv4 = "10.0.0.3"; ipv6 = "fdfe:dcba:9877::3";}]; Proteus-NUC = [{ipv4 = "100.64.161.20"; ipv6 = "fd7a:115c:a1e0::cd3a:a114"; domains = {A = ["@" "ns1" "v4"]; AAAA = ["@" "ns1" "v6"]; CNAME = ["aria2"];};} {ipv4 = "10.0.0.2"; ipv6 = "fdfe:dcba:9877::2"; domains = {A = ["ns1" "v4"]; AAAA = ["ns1" "v6"];};}];};
  # => ''
  # garage IN CNAME Proteus-Desktop
  # @ IN A 100.64.161.20
  # ns1 IN A 100.64.161.20
  # v4 IN A 100.64.161.20
  # @ IN AAAA fd7a:115c:a1e0::cd3a:a114
  # ns1 IN AAAA fd7a:115c:a1e0::cd3a:a114
  # v6 IN AAAA fd7a:115c:a1e0::cd3a:a114
  # aria2 IN CNAME Proteus-NUC
  # ns1 IN A 10.0.0.2
  # v4 IN A 10.0.0.2
  # ns1 IN AAAA fdfe:dcba:9877::2
  # v6 IN AAAA fdfe:dcba:9877::2
  # ''
  gen_subdomain_records = hosts_cfg:
    lib.concatLines (
      lib.foldlAttrs (acc_1: hostname: ifaces:
        acc_1
        ++ (
          lib.foldl (acc_2: iface: (
            acc_2
            ++ (lib.foldlAttrs (acc_3: type: subs:
              acc_3
              ++ (map (sub: "${sub} IN ${type} ${
                  if type == "A"
                  then iface.ipv4
                  else if type == "AAAA"
                  then iface.ipv6
                  else if type == "CNAME"
                  then hostname
                  else throw "Unsupported record type ${type}"
                }")
                subs))) []
            iface.domains
          )) []
          ifaces
        )) []
      hosts_cfg
    );

  gen_reverse_v4_records = domain: nets_cfg: hosts_cfg:
    lib.zipAttrsWith (_: v: lib.concatLines (builtins.concatLists v)) (lib.imap0 (
        net_idx: net_cfg:
          lib.foldlAttrs (acc_0: hostname: ifaces:
            acc_0
            // (let
              iface = builtins.elemAt ifaces net_idx;

              splited_ipv4 = lib.splitString "." iface.ipv4;
              prefix = builtins.concatStringsSep "." (lib.reverseList (lib.take net_cfg.v4PrefixLen splited_ipv4));
              host_octets = builtins.concatStringsSep "." (lib.reverseList (lib.drop net_cfg.v4PrefixLen splited_ipv4));
            in
              lib.optionalAttrs (iface.ipv4 != null) {
                ${prefix} =
                  # Top merge
                  (lib.optionals (acc_0 ? ${prefix}) acc_0.${prefix})
                  ++ ["${host_octets} IN PTR ${hostname}.${domain}"]
                  ++ (lib.optionals (iface ? domains) (lib.foldlAttrs (acc_1: type: subs:
                    acc_1
                    ++ (lib.optionals (type != "AAAA") (map (sub:
                      lib.optionalString (!lib.hasInfix "*" sub) "${host_octets} IN PTR ${
                        if sub != "@"
                        then "${sub}.${domain}."
                        else "${domain}."
                      }")
                    subs))) []
                  iface.domains));
              })) {}
          hosts_cfg
      )
      nets_cfg);

  gen_reverse_v6_records = domain: nets_cfg: hosts_cfg:
    lib.zipAttrsWith (_: v: lib.concatLines (builtins.concatLists v)) (lib.imap0 (
        net_idx: net_cfg:
          lib.foldlAttrs (acc_0: hostname: ifaces:
            acc_0
            // (let
              iface = builtins.elemAt ifaces net_idx;

              split_double_colon = lib.splitString "::" iface.ipv6;

              pad_hex = s: let
                len = builtins.stringLength s;
              in
                if len == 0
                then "0000"
                else if len == 1
                then "000${s}"
                else if len == 2
                then "00${s}"
                else if len == 3
                then "0${s}"
                else s;
              left_padded = map pad_hex (lib.splitString ":" (builtins.head split_double_colon));
              right_padded = map pad_hex (lib.splitString ":" (lib.last split_double_colon));

              missing_segments = builtins.genList (_: "0000") (8 - (builtins.length left_padded + builtins.length right_padded));
              formated_ipv6 = lib.reverseList (lib.concatMap lib.stringToCharacters (left_padded ++ missing_segments ++ right_padded));

              host_hexes = builtins.concatStringsSep "." (lib.take ((128 - net_cfg.v6PrefixLen) / 4) formated_ipv6);
              prefix = builtins.concatStringsSep "." (lib.drop ((128 - net_cfg.v6PrefixLen) / 4) formated_ipv6);
            in
              lib.optionalAttrs (iface.ipv6 != null) {
                ${prefix} =
                  (lib.optionals (acc_0 ? ${prefix}) acc_0.${prefix})
                  ++ ["${host_hexes} IN PTR ${hostname}.${domain}."]
                  ++ (lib.optionals (iface ? domains) (lib.foldlAttrs (acc_1: type: subs:
                    acc_1
                    ++ (lib.optionals (type != "A") (map (sub:
                      lib.optionalString (!lib.hasInfix "*" sub) "${host_hexes} IN PTR ${
                        if sub != "@"
                        then "${sub}.${domain}."
                        else "${domain}."
                      }")
                    subs))) []
                  iface.domains));
              })) {}
          hosts_cfg
      )
      nets_cfg);
  ## END Functions

  # Compute Dynamic State based on options
  gen_zone_head = ns: adm_email: domain: ''
    $ORIGIN ${domain}.
    $TTL ${cfg.soa.minimal_ttl}
    @ IN SOA  ${ns}. ${lib.replaceString "@" "." adm_email}. (
              ${cfg.soa.serial}       ; Serial
              ${cfg.soa.refresh}      ; Refresh
              ${cfg.soa.retry}        ; Retry
              ${cfg.soa.expire}       ; Expire
              ${cfg.soa.minimal_ttl}) ; Minimum TTL
    ; Nameserver definitions
    @ IN NS   ${ns}.
  '';

  # Generate zones dynamically based on the networks defined in the options
  domains =
    lib.mapAttrs (domain: _cfg: let
      partial_zone_head = gen_zone_head _cfg.nameServer _cfg.adminEmail;
    in {
      main_zone = pkgs.writeText "${_cfg.domain}.zone" (partial_zone_head _cfg.domain
        + ''
          ; Grouped Host Records
          ${lib.concatStringsSep "\n" (map (net_cfg: ''
              ${gen_v4_records _cfg.hosts}
              ${gen_v6_records _cfg.hosts}
            '')
            _cfg.networks)}
          ; Subdomain Services
          ${gen_subdomain_records _cfg.hosts}
        '');
      # Generate reverse zones dynamically for all configured networks
      reverse_v4_zones = lib.mapAttrs' (
        prefix: records:
          lib.nameValuePair "${prefix}.in-addr.arpa.zone" (pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
            ${partial_zone_head "${prefix}.in-addr.arpa"}
            ; PTR Records
            ${records}
          '')
      ) (gen_reverse_v4_records _cfg.domain _cfg.networks _cfg.hosts);
      reverse_v6_zones = lib.mapAttrs' (
        prefix: records:
          lib.nameValuePair "${prefix}.ip6.arpa.zone" (pkgs.writeText "${prefix}.ip6.arpa.zone" ''
            ${partial_zone_head "${prefix}.ip6.arpa"}
            ; PTR Records
            ${records}
          '')
      ) (gen_reverse_v6_records _cfg.domain _cfg.networks _cfg.hosts);
    })
    cfg.domains;
in {
  options.services.automateBind = {
    enable = lib.mkEnableOption "Automated Bind DNS Zones generation";
    debug = lib.mkOption {type = lib.types.anything;};
    domains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "TBD";
          };
          nameServer = lib.mkOption {
            type = lib.types.str;
            default = "ns1.${config.domain}";
            description = "TBD";
          };
          adminEmail = lib.mkOption {
            type = lib.types.str;
            default = "admin.${config.domain}";
            description = "TBD";
          };
          networks = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                v4PrefixLen = lib.mkOption {
                  type = lib.types.int;
                  description = "TBD";
                };
                v6PrefixLen = lib.mkOption {
                  type = lib.types.int;
                  description = "TBD";
                };
              };
            });
            default = {};
            description = "TBD";
          };
          hosts = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
              options = {
                ipv4 = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "TBD";
                };
                ipv6 = lib.mkOption {
                  type = with lib.types; nullOr str;
                  default = null;
                  description = "TBD";
                };
                domains = lib.mkOption {
                  type = lib.types.submodule {
                    options = {
                      A = lib.mkOption {
                        type = with lib.types; listOf str;
                        default = [];
                        description = "TBD";
                      };
                      AAAA = lib.mkOption {
                        type = with lib.types; listOf str;
                        default = [];
                        description = "TBD";
                      };
                      CNAME = lib.mkOption {
                        type = with lib.types; listOf str;
                        default = [];
                        description = "TBD";
                      };
                    };
                  };
                  default = {};
                  description = "TBD";
                };
              };
            }));
            default = {};
            description = "TBD";
          };
        };
      }));
      default = {};
      description = "TBD";
      example = {
        "proteus.eu.org" = {
          networks = [
            {
              v4PrefixLen = 1;
              v6PrefixLen = 48;
            }
            {
              v4PrefixLen = 3;
              v6PrefixLen = 64;
            }
          ];
          hosts = {
            Proteus-Desktop = [
              {
                ipv4 = "100.89.227.22";
                ipv6 = "fd7a:115c:a1e0::1a01:e318";
                domains.CNAME = ["garage"];
              }
              {
                ipv4 = "10.0.0.3";
                ipv6 = "fdfe:dcba:9877::3";
              }
            ];
            Proteus-NUC = [
              {
                ipv4 = "100.64.161.20";
                ipv6 = "fd7a:115c:a1e0::cd3a:a114";
                domains = {
                  A = ["@" "ns1" "v4"];
                  AAAA = ["@" "ns1" "v6"];
                  CNAME = ["aria2"];
                };
              }
              {
                ipv4 = "10.0.0.2";
                ipv6 = "fdfe:dcba:9877::2";
                domains = {
                  A = ["ns1" "v4"];
                  AAAA = ["ns1" "v6"];
                };
              }
            ];
          };
        };
      };
    };
    soa = {
      serial = lib.mkOption {
        type = lib.types.str;
        default = "2026051809";
      };
      refresh = lib.mkOption {
        type = lib.types.str;
        default = "3600";
      };
      retry = lib.mkOption {
        type = lib.types.str;
        default = "1800";
      };
      expire = lib.mkOption {
        type = lib.types.str;
        default = "604800";
      };
      minimal_ttl = lib.mkOption {
        type = lib.types.str;
        default = "86400";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.automateBind.debug = domains;
    # services.bind = {
    #   zones =
    #     {
    #       ${cfg.domain} = {
    #         master = true;
    #         file = main_zone.name;
    #         extraConfig = "dnssec-policy custom;";
    #       };
    #     }
    #     // (lib.mapAttrs' (_: z:
    #       lib.nameValuePair (lib.removeSuffix ".zone" z.name) {
    #         master = true;
    #         file = z.name;
    #         extraConfig = "dnssec-policy custom;";
    #       })
    #     reverse_v4_zones)
    #     // (lib.mapAttrs' (_: z:
    #       lib.nameValuePair (lib.removeSuffix ".zone" z.name) {
    #         master = true;
    #         file = z.name;
    #         extraConfig = "dnssec-policy custom;";
    #       })
    #     reverse_v6_zones);
    # };
  };
}
