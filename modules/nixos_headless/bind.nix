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

  gen_v4_records = suffix:
    lib.foldlAttrs (acc_1: hostname: host_val: (lib.concatStrings [
      (lib.optionalString (acc_1 != "") "${acc_1}\n") # Prepend if not first loop
      (lib.foldl (acc_2: iface: (lib.concatStrings [
          (lib.optionalString (acc_2 != "") "${acc_2}\n")
          (
            lib.optionalString (iface ? ipv4)
            "${hostname}${lib.optionalString (suffix != "") ".${suffix}"} IN A ${iface.ipv4}"
          )
        ])) ""
        host_val)
    ])) "";

  gen_v6_records = suffix:
    lib.foldlAttrs (acc: hostname: v: (lib.concatStrings [
      "${lib.optionalString (acc != "") "${acc}\n"}"
      "${hostname}${lib.optionalString (suffix != "") ".${suffix}"}"
      " IN AAAA ${v.ipv6}"
    ])) "";

  gen_subdomain_records = hosts:
    lib.concatLines (
      lib.foldlAttrs (acc_1: hostname: host_val:
        acc_1
        ++ (
          lib.foldlAttrs (acc_2: type: subs:
            acc_2
            ++ (map (sub: "${sub} IN ${type} ${
                if type == "A"
                then host_val.ipv4
                else if type == "AAAA"
                then host_val.ipv6
                else if type == "CNAME"
                then hostname
                else throw "Unsupported record type ${type}"
              }")
              subs)) []
          host_val.domains
        )) []
      hosts
    );

  gen_reverse_v4_records = depth: domain: hosts:
    lib.foldlAttrs (acc: hostname: host_val:
      lib.recursiveUpdate acc (let
        splited_ipv4 = lib.splitString "." host_val.ipv4;
        prefix = builtins.concatStringsSep "." (lib.reverseList (lib.take depth splited_ipv4));
        host_octets = builtins.concatStringsSep "." (lib.reverseList (lib.drop depth splited_ipv4));
      in {
        ${prefix} = ''
          ${lib.optionalString (acc ? ${prefix}) "${acc.${prefix}}\n"}${host_octets} IN PTR ${hostname}.${domain}.
          ${lib.optionalString (host_val ? domains) (let
            records = lib.foldlAttrs (acc: type: subs:
              acc
              ++ lib.optionals (type != "AAAA") (map (sub:
                lib.optionalString (!lib.hasInfix "*" sub) "${host_octets} IN PTR ${
                  if sub != "@"
                  then "${sub}.${domain}."
                  else "${domain}."
                }")
              subs)) []
            host_val.domains;
          in (lib.concatLines (lib.unique records)))}
        '';
      })) {}
    hosts;

  gen_reverse_v6_records = prefix_len: domain: hosts:
    lib.foldlAttrs (acc: hostname: host_val:
      lib.recursiveUpdate acc (let
        split_double_colon = lib.splitString "::" host_val.ipv6;
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
        host_hexes = builtins.concatStringsSep "." (lib.take ((128 - prefix_len) / 4) formated_ipv6);
        prefix = builtins.concatStringsSep "." (lib.drop ((128 - prefix_len) / 4) formated_ipv6);
      in {
        "${prefix}" = ''
          ${lib.optionalString (acc ? ${prefix}) "${acc.${prefix}}\n"}${host_hexes} IN PTR ${hostname}.${domain}.
          ${lib.optionalString (host_val ? domains) (let
            records = lib.foldlAttrs (acc: type: subs:
              acc
              ++ lib.optionals (type != "A") (map (sub:
                lib.optionalString (!lib.hasInfix "*" sub) "${host_hexes} IN PTR ${
                  if sub != "@"
                  then "${sub}.${domain}."
                  else "${domain}."
                }")
              subs)) []
            host_val.domains;
          in (lib.concatLines (lib.unique records)))}
        '';
      })) {}
    hosts;
  ## END Functions

  # Compute Dynamic State based on options
  gen_zone_head = domain: ns: adm_email: ''
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
      zone_head = gen_zone_head _cfg.domain _cfg.nameServer _cfg.adminEmail;
    in {
      test = gen_v4_records "" _cfg.hosts;
      # main_zone = pkgs.writeText "${_cfg.domain}.zone" (zone_head
      #   + ''
      #     ; Grouped Host Records
      #     ${lib.concatStringsSep "\n" (map (net_cfg: ''
      #         ; --- Network: ${} ---
      #         ${gen_v4_records net_cfg.suffix (lib.filterAttrs (_: v: v ? ipv4) _cfg.hosts)}
      #         ${gen_v6_records net_cfg.suffix (rename_attr_to netCfg.ipv6Attr "ipv6" cfg.hosts)}
      #       '')
      #       _cfg.networks)}
      #     ; Subdomain Services
      #     ${gen_subdomain_records (lib.filterAttrs (_: v: v ? domains) cfg.hosts)}
      #   '');
      # # Generate reverse zones dynamically for all configured networks
      # reverse_v4_zones =
      #   lib.foldlAttrs (
      #     acc: netName: netCfg:
      #       acc
      #       // (builtins.mapAttrs (prefix: records:
      #         pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
      #           ${zone_head "${prefix}.in-addr.arpa"}
      #           ; PTR Records
      #           ${records}
      #         '') (gen_reverse_v4_records netCfg.v4Depth cfg.domain (rename_attr_to netCfg.ipv4Attr "ipv4" cfg.hosts)))
      #   ) {}
      #   cfg.networks;
      # reverse_v6_zones =
      #   lib.foldlAttrs (
      #     acc: netName: netCfg:
      #       acc
      #       // (builtins.mapAttrs (prefix: records:
      #         pkgs.writeText "${prefix}.ip6.arpa.zone" ''
      #           ${zone_head "${prefix}.ip6.arpa"}
      #           ; PTR Records
      #           ${records}
      #         '') (gen_reverse_v6_records netCfg.v6PrefixLen cfg.domain (rename_attr_to netCfg.ipv6Attr "ipv6" cfg.hosts)))
      #   ) {}
      #   cfg.networks;
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
                suffix = lib.mkOption {
                  type = lib.types.str;
                  default = "";
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
              suffix = "et";
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
