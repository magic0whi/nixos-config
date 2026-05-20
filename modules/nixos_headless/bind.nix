{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.bind;
  bindZoneOptions = {
    name,
    config,
    ...
  }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Name of the zone.";
      };
      master = lib.mkOption {
        description = "Master=false means slave server";
        type = lib.types.bool;
      };
      file = lib.mkOption {
        type = lib.types.either lib.types.str lib.types.path;
        description = "Zone file resource records contain columns of data, separated by whitespace, that define the record.";
      };
      masters = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of servers for inclusion in stub and secondary zones.";
      };
      slaves = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Addresses who may request zone transfers.";
        default = [];
      };
      allowQuery = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''
          List of address ranges allowed to query this zone. Instead of the address(es), this may instead
          contain the single string "any".
        '';
        default = ["any"];
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
        description = "Extra zone config to be appended at the end of the zone section.";
        default = "";
      };
    };
  };
  ## BEGIN Functions (Kept exactly as your original logic)
  # Usage example
  # gen_v4_records {Proteus-Desktop = [{ipv4 = "100.89.227.22";} {ipv4 = "10.0.0.3";}]; Proteus-NUC = [{ipv4 = "100.64.161.20"; } {ipv4 = "10.0.0.2";}];}
  # => ''
  # Proteus-Desktop IN A 100.89.227.22
  # Proteus-Desktop IN A 10.0.0.3
  # Proteus-NUC IN A 100.64.161.20
  # Proteus-NUC IN A 10.0.0.2
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

  # Usage example
  # gen_reverse_v4_records "example.com" [{v4PrefixLen = 1; v6PrefixLen = 48;} {v4PrefixLen = 3; v6PrefixLen = 64;}] {Proteus-Desktop = [{ipv4 = "100.89.227.22"; ipv6 = "fd7a:115c:a1e0::1a01:e318"; domains.CNAME = ["garage"];} {ipv4 = "10.0.0.3"; ipv6 = "fdfe:dcba:9877::3";}]; Proteus-NUC = [{ipv4 = "100.64.161.20"; ipv6 = "fd7a:115c:a1e0::cd3a:a114"; domains = {A = ["@" "ns1" "v4"]; AAAA = ["@" "ns1" "v6"]; CNAME = ["aria2"];};} {ipv4 = "10.0.0.2"; ipv6 = "fdfe:dcba:9877::2"; domains = {A = ["ns1" "v4"]; AAAA = ["ns1" "v6"]; CNAME = ["git"];};}];}
  # {
  #   "0.0.10" = ''
  #     3 IN PTR Proteus-Desktop.example.com
  #     2 IN PTR Proteus-NUC.example.com
  #     2 IN PTR ns1.example.com.
  #     2 IN PTR v4.example.com.
  #     2 IN PTR git.example.com.
  #
  #   '';
  #   "100" = ''
  #   22.227.89 IN PTR Proteus-Desktop.example.com
  #   22.227.89 IN PTR garage.example.com.
  #   20.161.64 IN PTR Proteus-NUC.example.com
  #   20.161.64 IN PTR example.com.
  #   20.161.64 IN PTR ns1.example.com.
  #   20.161.64 IN PTR v4.example.com.
  #   20.161.64 IN PTR aria2.example.com.
  #
  #   '';
  # };
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
                  ++ ["${host_octets} IN PTR ${hostname}.${domain}."]
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

              # IPv6 Reverse Logic (Zero-Compression Expansion)
              # 1. Split by "::" to handle zero-compression
              # e.g., "fd7a:115c:a1e0::cd3a:a114" -> ["fd7a:115c:a1e0" "cd3a:a114"]
              split_double_colon = lib.splitString "::" iface.ipv6;

              # 2. Split the IP into a list, and pad add segments to 4 characters
              # e.g., Left part: ["fd7a" "115c" "a1e0"], right part: ["cd3a" "a114"]
              # Helper: Pad a string to 4 characters with leading zeros
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

              # 3. Calculate and generate missing zero segments (IPv6 has 8 total segments)
              # e.g., Missing count is `8 - (3 + 2) = 3`, so the missing_segments is: ["0000" "0000" "0000"]
              miss_segs = builtins.genList (_: "0000") (8 - (builtins.length left_padded + builtins.length right_padded));

              # 4. Construct the full 32-character string, iterate and break it to chars list, them reverse it
              # e.g., ["fd7a" "115c" "a1e0" "0000" "0000" "0000" "cd3a" "a114"]
              # -> ["f" "d" "7" "a" "1" "1" "5" "c" "a" "1" "e" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "c" "d" "3" "a" "a" "1" "1" "4"]
              # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
              formated_ipv6 = lib.reverseList (lib.concatMap lib.stringToCharacters (left_padded ++ miss_segs ++ right_padded));

              # For a /48 prefix. the PTR length is `128 - 48 = 80` bits (20 hex chars), and the Zone Prefix is 48
              # ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
              # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0"]
              # -> "4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0"
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
  gen_zone_head = _cfg: domain: ''
    $ORIGIN ${domain}.
    $TTL ${_cfg.soa.minimal_ttl}
    @ IN SOA  ${_cfg.nameServer}. ${lib.replaceString "@" "." _cfg.adminEmail}. (
              ${_cfg.soa.serial}       ; Serial
              ${_cfg.soa.refresh}      ; Refresh
              ${_cfg.soa.retry}        ; Retry
              ${_cfg.soa.expire}       ; Expire
              ${_cfg.soa.minimal_ttl}) ; Minimum TTL
    ; Nameserver definitions
    @ IN NS   ${_cfg.nameServer}.
  '';

  # Generate zones dynamically based on the networks defined in the options
  processed_domains =
    lib.mapAttrs (domain: _cfg: let
      partial_zone_head = gen_zone_head _cfg;
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
          lib.nameValuePair "${prefix}.in-addr.arpa" (pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
            ${partial_zone_head "${prefix}.in-addr.arpa"}
            ; PTR Records
            ${records}
          '')
      ) (gen_reverse_v4_records _cfg.domain _cfg.networks _cfg.hosts);
      reverse_v6_zones = lib.mapAttrs' (
        prefix: records:
          lib.nameValuePair "${prefix}.ip6.arpa" (pkgs.writeText "${prefix}.ip6.arpa.zone" ''
            ${partial_zone_head "${prefix}.ip6.arpa"}
            ; PTR Records
            ${records}
          '')
      ) (gen_reverse_v6_records _cfg.domain _cfg.networks _cfg.hosts);
    in {
      zones =
        {
          ${_cfg.domain} =
            _cfg.bindZoneOptions
            // {
              name = _cfg.domain;
              file =
                if _cfg.mutable
                then main_zone.name
                else main_zone;
            };
        }
        // (builtins.mapAttrs (name: zone_file:
          _cfg.bindZoneOptions
          // {
            inherit name;
            file =
              if _cfg.mutable
              then zone_file.name
              else zone_file;
          })
        reverse_v4_zones)
        // (builtins.mapAttrs (name: zone_file:
          _cfg.bindZoneOptions
          // {
            inherit name;
            file =
              if _cfg.mutable
              then zone_file.name
              else zone_file;
          })
        reverse_v6_zones);

      # Collect all the derivation files that need to be copied if mutable = true
      inherit (_cfg) mutable;
      zone_files = [main_zone] ++ (builtins.attrValues reverse_v4_zones) ++ (builtins.attrValues reverse_v6_zones);
    })
    cfg.domains;
in {
  options.services.bind = {
    debug = lib.mkOption {type = lib.types.anything;};
    domains = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({
        name,
        config,
        ...
      }: {
        options = {
          mutable = lib.mkEnableOption "TBD";
          bindZoneOptions = lib.mkOption {
            type = lib.types.submodule bindZoneOptions;
          };
          soa = {
            serial = lib.mkOption {
              type = lib.types.str;
              default = "1970010100";
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
        "example.com" = {
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
  };

  config = lib.mkIf cfg.enable {
    services.bind.debug = processed_domains;
    services.bind = {
      zones = lib.foldlAttrs (acc: _: pcsd_domain: acc // pcsd_domain.zones) {} processed_domains;
      checkConfig = lib.mkIf (lib.foldlAttrs (any: _: domain:
          if any
          then any
          else domain.mutable)
        false
        config.services.bind.domains)
      false;
    };

    systemd.services.bind = let
      # Filter out only the mutable domains
      mutable_domains = lib.filterAttrs (_: pcsd_domain: pcsd_domain.mutable) processed_domains;
      # Generate the install commands for all files (main + reverse) for each mutable domain
      installScripts = lib.mapAttrsToList (_: pcsd_domain:
        lib.concatMapStringsSep "\n" (file: "install -m 0644 ${file} ${config.services.bind.directory}/${file.name}")
        pcsd_domain.zone_files)
      mutable_domains;
    in
      # Concatenate all the generated install scripts into one big preStart script
      lib.mkIf (mutable_domains != {}) {preStart = lib.mkAfter (lib.concatLines installScripts);};
  };
}
