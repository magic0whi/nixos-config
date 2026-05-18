{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: let
  tailnet_prefix_length = 48;
  soa_parms = {
    serial = "2026051802"; # Serial (YYYYMMDDNN)
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
  depth = 3;
  nuc_ipv4 = myvars.networking.hosts_addr.Proteus-NUC.ipv4;
  nuc_ipv6 = myvars.networking.hosts_addr.Proteus-NUC.ipv6;
  desktop_ipv4 = myvars.networking.hosts_addr.Proteus-Desktop.ipv4;
  desktop_ipv6 = myvars.networking.hosts_addr.Proteus-Desktop.ipv6;

  # =========================================
  # IPv4 Reverse Logic
  # =========================================
  gen_reverse_prefix_v4 = ipv4: let
    # 1. Split the IP into a list of octets, e.g. "100.64.161.20" -> ["100" "64" "161" "20"]
    octets = lib.splitString "." ipv4;

    # 2. Extract the first 3 octets, reverse them, and join with dots
    # e.g. ["100" "64" "161" "20"] -> ["100" "64" "161"] -> ["161" "64" "100"] -> "161.64.100"
    reverse_prefix = builtins.concatStringsSep "." (lib.reverseList (lib.take 3 octets));
  in
    # 3. Construct the full dynamic zone name, e.g. "161.64.100.in-addr.arpa"
    "${reverse_prefix}.in-addr.arpa";

  # ==========================================
  # IPv6 Reverse Logic (Zero-Compression Expansion)
  # ==========================================
  gen_reversed_chars_v6 = ipv6: let
    # 1. Split by "::" to handle zero-compression, e.g. "fd7a:115c:a1e0::cd3a:a114" -> ["fd7a:115c:a1e0" "cd3a:a114"]
    split_double_colon = lib.splitString "::" ipv6;

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

    # 4. Construct the full 32-character string
    # e.g.: ["fd7a" "115c" "a1e0", "0000" "0000" "0000" "cd3a" "a114"] -> "fd7a115ca1e0000000000000cd3aa114"
    full_ipv6_str = builtins.concatStringsSep "" (left_padded ++ missing_segments ++ right_padded);
  in
    # 5. Reverse it character by character
    # e.g. "fd7a115ca1e0000000000000cd3aa114"
    # -> ["f" "d" "7" "a" "1" "1" "5" "c" "a" "1" "e" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "c" "d" "3" "a" "a" "1" "1" "4"]
    # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
    lib.reverseList (lib.stringToCharacters full_ipv6_str);

  # Tailscale uses a /48 prefix. So the PTR length is `128 - 48 = 80` bits (20 hex chars), and the Zone Prefix is 48
  # bits (12 hex chars). e.g.
  # ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
  # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0"]
  # -> "4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0"
  gen_v6_ptr_host = {
    reversed_chars,
    prefix_len,
  }: (builtins.concatStringsSep "." (lib.take ((128 - prefix_len) / 4) reversed_chars));
  # e.g.
  # ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
  # -> ["0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"] -> "0.e.1.a.c.5.1.1.a.7.d.f"
  gen_v6_zone_prefix = {
    reversed_chars,
    prefix_len,
  }: (builtins.concatStringsSep "." (lib.drop ((128 - prefix_len) / 4) reversed_chars));

  # =========================================
  # Forward Zone (proteus.eu.org)
  # =========================================
  # Don't forget update the SOA Serial
  # TODO: Implements
  # 1. (COMPLETED) Automate records generate
  # myvars.networking.hosts_addr.<hostname>.domain.<type> = ["immich" "sftpgo"];
  # And will generate the following records in zone:
  # <hostname> IN A    myvars.networking.hosts_addr.<hostname>.ipv4
  # <hostname> IN AAAA myvars.networking.hosts_addr.<hostname>.ipv6
  # immich IN CNAME <hostname>
  # sftpgo IN CNAME <hostname>
  #
  # 2. Automate reverse zone generate
  # For ipv4, give a octets_merge_depth variable to decide which level
  # e.g., Merge 100.*.*.* to one zone for `octets_merge_depth = 1`; Merge 100.64.*.* to one zone for `octets_merge_depth = 2`
  proteus_zone = pkgs.writeText "${myvars.domain}.zone" ((zone_head myvars.domain)
    + ''
      ; Grouped Host Records - IPv4
      ${lib.foldlAttrs (acc: n: v: "${lib.optionalString (acc != "") "${acc}\n"}${n} IN A ${v.ipv4}") ""
        (lib.filterAttrs (_: v: v ? ipv4) myvars.networking.hosts_addr)}

      ; Grouped Host Records - IPv6
      ${lib.foldlAttrs (acc: n: v: "${lib.optionalString (acc != "") "${acc}\n"}${n} IN AAAA ${v.ipv6}") ""
        (lib.filterAttrs (_: v: v ? ipv6) myvars.networking.hosts_addr)}

      ; EasyTier Hostnames
      ; For me `lib.foldlAttrs` takes a bit longer to understand
      ; lib.foldlAttrs (acc: name: val: <new_acc>) acc attrset
      ${let
        et_hosts = lib.filterAttrs (_: v: v ? et_ipv4 || v ? et_ipv6) myvars.networking.hosts_addr;

        et_v4_hosts = lib.foldlAttrs (acc: n: v: "${lib.optionalString (acc != "") "${acc}\n"}${n}.et IN A ${v.et_ipv4}") "" et_hosts;
        et_v6_hosts = lib.foldlAttrs (acc: n: v: "${lib.optionalString (acc != "") "${acc}\n"}${n}.et IN AAAA ${v.et_ipv6}") "" et_hosts;
      in "${et_v4_hosts}\n${et_v6_hosts}"}

      ; Subdomain Services
      ${let
        domain_hosts = lib.filterAttrs (_: v: v ? domains) myvars.networking.hosts_addr;
        records =
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
      in (lib.concatLines records)}
    '');
  # =========================================
  # IPv4 Reverse Zones
  # =========================================
  gen_reverse_v4_zones = depth:
    lib.foldlAttrs
    (acc: n: v:
      lib.recursiveUpdate acc (let
        splited_ipv4 = lib.splitString "." v.ipv4;
        prefix = lib.concatStringsSep "." (lib.reverseList (lib.take depth splited_ipv4));
      in {
        ${prefix} = "${
          if acc ? ${prefix}
          then acc.${prefix}
          else ""
        }\n${lib.concatStringsSep "." (lib.drop depth splited_ipv4)} IN PTR ${n}.${myvars.tailnet}.";
        # {"${lib.concatStringsSep "." (lib.drop depth splited_ipv4)}" = n;};
      })) {}
    myvars.networking.hosts_addr;
  reverse_v4_zones = builtins.mapAttrs (prefix: records:
    # pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
    ''
      ${zone_head "${prefix}.in-addr.arpa."}
      ; PTR Record
      ${records}
    '')
  (gen_reverse_v4_zones depth);

  # In tailnet, the IPv4 reverse zone name are likely to vary
  nuc_reverse_zone_v4_name = gen_reverse_prefix_v4 nuc_ipv4;
  nuc_reverse_zone_v4 = let
    content = ''
      ${zone_head nuc_reverse_zone_v4_name}

      ; PTR Record for last octet pointing to Tailscale domain
      ${lib.last (lib.splitString "." nuc_ipv4)} IN PTR proteus-nuc.${myvars.tailnet}.
    '';
    # in builtins.trace content (pkgs.writeText "${nuc_reverse_zone_v4_name}.zone" content);
  in (pkgs.writeText "${nuc_reverse_zone_v4_name}.zone" content);

  desktop_reverse_zone_v4_name = gen_reverse_prefix_v4 desktop_ipv4;
  desktop_reverse_zone_v4 = pkgs.writeText "${desktop_reverse_zone_v4_name}.zone" ''
    ${zone_head desktop_reverse_zone_v4_name}

    ${lib.last (lib.splitString "." desktop_ipv4)} IN PTR proteus-desktop.${myvars.tailnet}.
  '';
  # =========================================
  # IPv6 Reverse Zone
  # =========================================
  nuc_reversed_chars = gen_reversed_chars_v6 nuc_ipv6;

  nuc_ipv6_ptr_host = gen_v6_ptr_host {
    reversed_chars = nuc_reversed_chars;
    prefix_len = tailnet_prefix_length;
  };
  desktop_ipv6_ptr_host = gen_v6_ptr_host {
    reversed_chars = gen_reversed_chars_v6 desktop_ipv6;
    prefix_len = tailnet_prefix_length;
  };
  # e.g. "0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa"
  reverse_zone_v6_name = "${
    gen_v6_zone_prefix {
      reversed_chars = nuc_reversed_chars;
      prefix_len = tailnet_prefix_length;
    }
  }.ip6.arpa";
  reverse_zone_v6 = pkgs.writeText "${reverse_zone_v6_name}.zone" ''
    ${zone_head reverse_zone_v6_name}

    ; PTR Record for the host portion pointing to Tailscale domain
    ${nuc_ipv6_ptr_host} IN PTR proteus-nuc.${myvars.tailnet}.
    ${desktop_ipv6_ptr_host} IN PTR proteus-desktop.${myvars.tailnet}.
  '';
in {
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
  systemd.services.bind.preStart = lib.mkAfter ''
    install -m 0644 ${proteus_zone} ${config.services.bind.directory}/${myvars.domain}.zone
    install -m 0644 ${nuc_reverse_zone_v4} ${config.services.bind.directory}/${nuc_reverse_zone_v4_name}.zone
    install -m 0644 ${desktop_reverse_zone_v4} ${config.services.bind.directory}/${desktop_reverse_zone_v4_name}.zone
    install -m 0644 ${reverse_zone_v6} ${config.services.bind.directory}/${reverse_zone_v6_name}.zone
  '';
  services.resolved.settings.Resolve = {
    DNSSEC = "allow-downgrade";
    Domains = [
      "~${myvars.domain}" # The '~' prefix makes this a routing domain
      "~${nuc_reverse_zone_v4_name}"
      "~${desktop_reverse_zone_v4_name}"
      "~${reverse_zone_v6_name}"
    ];
    DNS = ["${nuc_ipv4}#${myvars.domain}"];
  };
  # Trust Island
  # NOTE: Query the zone apex (`proteus.eu.org`, `161.64.100.in-addr.arpa`
  # `0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa`)
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#bind --command dnssec-dsfromkey -f - 161.64.100.in-addr.arpa
  # Or
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#ldns.examples --command ldns-key2ds -n /dev/stdin
  environment.etc."dnssec-trust-anchors.d/${myvars.domain}.positive".text = ''
    ${myvars.domain}. IN DS 19905 15 2 AC53E45BD2ECD7E4D8DED050FB08E0F37095AF97E0B6F73CE912A56CE5C542C0
  '';
  environment.etc."dnssec-trust-anchors.d/${nuc_reverse_zone_v4_name}.positive".text = ''
    ${nuc_reverse_zone_v4_name}. IN DS 32237 15 2 5F089BE41C87322212B05BAB4A760097235220F5346A1F51F6161728B77A0F8F
  '';
  environment.etc."dnssec-trust-anchors.d/${desktop_reverse_zone_v4_name}.positive".text = ''
    ${desktop_reverse_zone_v4_name}. IN DS 25153 15 2 B5B5AC75FDCC85AACBDF747323AC5F7CA8D8FC482D03C848DEE4EFAD79F7CD50
  '';
  environment.etc."dnssec-trust-anchors.d/${reverse_zone_v6_name}.positive".text = ''
    ${reverse_zone_v6_name}. IN DS 60960 15 2 DD09A9E95F7C7851FAC65FD39FDE55FAB2C001D5B37D744F98AA23C56FD63D16
  '';
  services.bind = {
    enable = true;
    checkConfig = false;
    # Persistent directory for DNSSEC key states.
    # NixOS defaults to /run/named, which clears on reboot.
    directory = "/srv/bind";
    # Access-control of what networks are allowed for recursive queries
    # cacheNetworks = [
    #   "127.0.0.0/8" "::1/128"
    #   "100.64.0.0/10" "fd7a:115c:a1e0::/48"
    #   "192.168.0.0/16"
    # ];
    forwarders = [];
    # Bind standard port 53 strictly to the specific interface IPs
    listenOn = with myvars.networking.hosts_addr.Proteus-NUC; [ipv4 et_ipv4];
    listenOnIpv6 = with myvars.networking.hosts_addr.Proteus-NUC; [ipv6 et_ipv4];

    # Inject the variables into the raw extraOptions string for DoT and DoH
    extraOptions = with myvars.networking.hosts_addr.Proteus-NUC; ''
      # Strictly Authoritative-Only Mode
      recursion no;

      # Raw DNS for local systemd-resolved and direct Tailscale clients
      listen-on port 53 { 127.0.0.1; ${ipv4}; };
      listen-on-v6 port 53 { ::1; ${ipv6}; };

      # Dedicated unencrypted TCP port strictly for Traefik's DoT proxy stream
      listen-on port 8530 proxy plain { 127.0.0.1; };
      listen-on-v6 port 8530 proxy plain { ::1; };

      # Plain HTTP endpoint strictly for Traefik's DoH forwarding
      listen-on port 8053 tls none http default { 127.0.0.1; };
      listen-on-v6 port 8053 tls none http default { ::1; };

      # Trust PROXYv2 headers from Traefik
      # Who is talking to me?
      allow-proxy { 127.0.0.1; ::1; };
      # Which of my doors are they knocking on?
      allow-proxy-on { 127.0.0.1; ::1; };

      allow-transfer { none; };
      allow-update { none; };
      server-id none;

      # Disable global validation if relying solely on the trusted island
      dnssec-validation no;
    '';
    extraConfig = ''
      # DNSSEC Trusted Island Policy
      dnssec-policy custom {
        keys {
          csk key-directory lifetime unlimited algorithm 15; # ED25519
        };
        max-zone-ttl 24h;
        signatures-refresh 8d; # Regenerate 8 days before expire
        signatures-validity 10d; # ZSK validity last for 10 days
        signatures-validity-dnskey 10d; # KSK validity last for 10 days
      };
    '';
    zones = {
      "${myvars.domain}" = {
        master = true;
        file = "${myvars.domain}.zone"; # Relative path
        # Apply the DNSSEC policy to sign the zone locally
        extraConfig = "dnssec-policy custom;";
      };
      "${nuc_reverse_zone_v4_name}" = {
        master = true;
        file = "${nuc_reverse_zone_v4_name}.zone";
        extraConfig = "dnssec-policy custom;";
      };
      "${desktop_reverse_zone_v4_name}" = {
        master = true;
        file = "${desktop_reverse_zone_v4_name}.zone";
        extraConfig = "dnssec-policy custom;";
      };
      "${reverse_zone_v6_name}" = {
        master = true;
        file = "${reverse_zone_v6_name}.zone";
        extraConfig = "dnssec-policy custom;";
      };
    };
  };
}
