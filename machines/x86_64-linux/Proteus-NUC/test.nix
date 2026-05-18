{
  lib,
  myvars,
  ...
}: {
  options.services.test = let
    soa_parms = {
      serial = "2026051403"; # Serial (YYYYMMDDNN)
      refresh = "3600"; # Refresh (1 hour)
      retry = "1800"; # Retry (30 minutes)
      expire = "604800"; # Expire (1 week)
      minimal_ttl = "86400"; # Minimum TTL
    };
    zone_head = _domain: ''
      $ORIGIN ${_domain}.
      $TTL ${soa_parms.minimal_ttl}
      @ IN SOA  ns1.${myvars.domain}. admin.${myvars.domain}. (
                ${soa_parms.serial}       ; Serial (YYYYMMDDNN)
                ${soa_parms.refresh}      ; Refresh (1 hour)
                ${soa_parms.retry}        ; Retry (30 minutes)
                ${soa_parms.expire}       ; Expire (1 week)
                ${soa_parms.minimal_ttl}) ; Minimum TTL
      ; Nameserver definitions
      @ IN NS   ns1.${myvars.domain}.
    '';
    depth = 1;
  in {
    debug_subdomain = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Step 1: map (sub: "${sub} IN CNAME Proteus-NUC") myvars.networking.hosts_addr.Proteus-NUC.domains.CNAME;
      # [
      #   "aria2 IN CNAME Proteus-NUC"
      #   "atuin IN CNAME Proteus-NUC"
      #   ...
      # ]
      # Step 2: lib.foldlAttrs
      #   (acc: type: subs:
      #     acc
      #     ++ (map (sub: "${sub} IN ${type} ${
      #         if type == "A"
      #         then myvars.networking.hosts_addr.Proteus-NUC.ipv4
      #         else if type == "AAAA"
      #         then myvars.networking.hosts_addr.Proteus-NUC.ipv6
      #         else if type == "CNAME"
      #         then "Proteus-NUC"
      #         else throw "Unexpected record type ${type}"
      #       }")
      #       subs)) []
      #   myvars.networking.hosts_addr.Proteus-NUC.domains;
      # [
      #   "@ IN A 100.64.161.20"
      #   "ns1 IN A 100.64.161.20"
      #   "@ IN AAAA fd7a:115c:a1e0::cd3a:a114"
      #   "ns1 IN AAAA fd7a:115c:a1e0::cd3a:a114"
      #   "aria2 IN CNAME Proteus-NUC"
      #   "atuin IN CNAME Proteus-NUC"
      #   ...
      # ]
      default = let
        domain_hosts = lib.filterAttrs (_: v: v ? domains) myvars.networking.hosts_addr;
      in
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
                subs))
            []
            host_val.domains
          ))
        []
        domain_hosts;
      description = "DEBUG";
    };
    debug_v4 = lib.mkOption {
      # type = lib.types.functionTo lib.types.attrs;
      type = lib.types.attrs;
      default = let
        gen_reverse_v4_zones = depth: domain:
          lib.foldlAttrs
          (acc: hostname: v:
            lib.recursiveUpdate acc (let
              splited_ipv4 = lib.splitString "." v.ipv4;
              prefix = lib.concatStringsSep "." (lib.reverseList (lib.take depth splited_ipv4));
              host_octets = lib.concatStringsSep "." (lib.drop depth splited_ipv4);
            in {
              ${prefix} = ''
                ${
                  lib.optionalString (acc ? ${prefix}) "${acc.${prefix}}\n"
                }${host_octets} IN PTR ${hostname}.${domain}.${
                  lib.optionalString (v ? domains) "\n${host_octets} IN PTR ${hostname}.${domain}."
                  # TODO implement subdomains
                  #             then let
                  #               records = lib.foldlAttrs
                  #         (acc: class: names: acc ++ (map (name: "${host_octets} IN PTR ${hostname}") names)) []
                  #         v.domains)
                  # in (lib.concatLines records)}
                }
              '';
              # {"${lib.concatStringsSep "." (lib.drop depth splited_ipv4)}" = n;};
            })) {}
          myvars.networking.hosts_addr;
      in
        builtins.mapAttrs (prefix: records:
          # pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
          ''
            ${zone_head "${prefix}.in-addr.arpa."}
            ; PTR Record
            ${records}
          '')
        (gen_reverse_v4_zones depth myvars.domain);

      description = "Identify different instances on same host";
    };
    debug_v6 = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      default = depth:
        lib.foldlAttrs
        (acc: n: v:
          lib.recursiveUpdate acc (let
            split_double_colon = lib.splitString "::" v.ipv6;

            # 2. Split the IP into a list, and pad add segments to 4 characters
            # e.g. Left part: ["fd7a" "115c" "a1e0"], right part: ["cd3a" "a114"]
            pad_hex = s: let
              len = builtins.stringLength s;
            in
              # Helper: Pad a string to 4 characters with leading zeros
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
            # e.g. Missing count is `8 - (3 + 2) = 3`, so the missing_segments is: ["0000" "0000" "0000"]
            missing_segments = let
              missing_count = 8 - (builtins.length left_padded + builtins.length right_padded);
            in (builtins.genList (_: "0000") missing_count);

            list_to_chars = list: lib.concatMap lib.stringToCharacters list;

            # 4. Construct the full 32-character string
            # e.g.: ["fd7a" "115c" "a1e0", "0000" "0000" "0000" "cd3a" "a114"] -> "fd7a115ca1e0000000000000cd3aa114"
            full_ipv6 = list_to_chars (left_padded ++ missing_segments ++ right_padded);
          in {
            "${lib.concatStringsSep "." (lib.reverseList (lib.take depth full_ipv6))}" = {
              "${lib.concatStringsSep "." (lib.drop depth full_ipv6)}" = n;
            };
          })) {}
        (lib.filterAttrs (_: v: v ? ipv6) myvars.networking.hosts_addr);
      description = "Identify different instances on same host";
    };
  };
}
