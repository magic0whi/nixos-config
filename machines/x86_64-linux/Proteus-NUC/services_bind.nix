{
  config,
  lib,
  myvars,
  ...
}: {
  networking.firewall = {
    allowedTCPPorts = [53 853];
    allowedUDPPorts = [53]; # Bind don't support DNS-over QUIC
  };
  services.bind = {
    enable = true;
    # Persistent directory for DNSSEC key states. Defaults to "/run/named", which clears on reboot.
    # directory = "/srv/bind";

    # Access-control of what networks are allowed for recursive queries
    # cacheNetworks = [
    #   "127.0.0.0/8" "::1/128"
    #   "100.64.0.0/10" "fd7a:115c:a1e0::/48"
    #   "192.168.0.0/16"
    # ];
    forwarders = [];
    # Bind standard port 53 strictly to the specific interface IPs
    listenOn =
      ["127.0.0.1"]
      ++ (lib.concatMap (iface: lib.optional (iface ? ipv4) iface.ipv4)
        myvars.networking.hosts_addr.${config.networking.hostName});
    listenOnIpv6 =
      ["::1"]
      ++ (lib.concatMap (iface: lib.optional (iface ? ipv6) iface.ipv6)
        myvars.networking.hosts_addr.${config.networking.hostName});
    # Inject the variables into the raw extraOptions string for DoT and DoH
    extraOptions = ''
      # Strictly Authoritative-Only Mode, implies 'empty-zones-enable no'
      recursion no;

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
    domains = {
      ${myvars.domain} = {
        bindZoneOptions = {
          master = true;
          # Apply the DNSSEC policy to sign the zone locally
          extraConfig = "dnssec-policy custom;";
        };
        mutable = true;
        soa = {
          rName = myvars.useremail;
          serial = "2026052301";
        };
        networks = [
          {
            v4PrefixLen = 10 / 8;
            v6PrefixLen = 48 / 4;
          }
          {
            v4PrefixLen = 24 / 8;
            v6PrefixLen = 64 / 4;
          }
        ];
        hosts = let
          allowed_hosts =
            ["Proteus-NUC" "Proteus-MBP14M4P" "Proteus-Desktop"]
            ++ map (i: "Proteus-NixOS-${toString i}") (lib.range 0 5);
        in
          lib.mapAttrs (_: ifaces:
            map (iface: lib.filterAttrs (key: _: builtins.elem key ["ipv4" "ipv6" "domains"]) iface) ifaces)
          (lib.filterAttrs (name: _: builtins.elem name allowed_hosts) myvars.networking.hosts_addr);
      };
    };
  };

  services.traefik = {
    staticConfigOptions.entryPoints.dot.address = ":853"; # Add the standard DoT port as a TCP entrypoint
    dynamicConfigOptions = {
      http = {
        routers.doh = {
          # Intercept standard DoH queries at the apex domain
          rule = lib.concatStrings [
            "("
            "Host(`${myvars.domain}`)"
            " || Host(`ns1.${myvars.domain}`)"
            " || Host(`${config.networking.hostName}.${myvars.tailnet}`)"
            ")"
            " && Path(`/dns-query`)"
          ];
          entryPoints = ["websecure"];
          tls = {};
          service = "doh";
        };
        # Use HTTP/2 Cleartext (h2c) when talking to BIND's local port.
        services.doh.loadBalancer.servers = [{url = "h2c://127.0.0.1:8053";} {url = "h2c://[::1]:8053";}];
      };
      tcp = {
        routers.dot = {
          rule = builtins.concatStringsSep " " [
            "HostSNI(`${myvars.domain}`)"
            "|| HostSNI(`ns1.${myvars.domain}`)"
            "|| HostSNI(`proteus-nuc.${myvars.tailnet}`)"
          ];
          entryPoints = ["dot"];
          service = "dot";
          tls = {};
        };
        # Forward raw DNS to BIND's local 53
        services.dot.loadBalancer = {
          proxyProtocol.version = 2;
          servers = [{address = "127.0.0.1:8530";} {address = "[::1]:8530";}];
        };
      };
    };
  };

  services.resolved.settings.Resolve = {
    DNSSEC = "allow-downgrade";
    Domains =
      [
        "~${myvars.domain}" # The '~' prefix makes this a routing domain
      ]
      ++ (lib.mapAttrsToList (_: zone:
        if (lib.isDerivation zone.file)
        then "~${zone.file.name}"
        else "~${zone.file}")
      config.services.bind.zones);

    DNS =
      (lib.concatMap (iface: lib.optional (iface ? ipv4) "${iface.ipv4}#${myvars.domain}")
        myvars.networking.hosts_addr.${config.networking.hostName})
      ++ (lib.concatMap (iface: lib.optional (iface ? ipv6) "${iface.ipv6}#${myvars.domain}")
        myvars.networking.hosts_addr.${config.networking.hostName});
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
  # environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v4_zones."100".name}.positive".text = ''
  #   ${lib.removeSuffix ".zone" reverse_v4_zones."100".name}. IN DS 32237 15 2 5F089BE41C87322212B05BAB4A760097235220F5346A1F51F6161728B77A0F8F
  # '';
  # environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v4_zones."192".name}.positive".text = ''
  #   ${lib.removeSuffix ".zone" reverse_v4_zones."192".name}. IN DS 25153 15 2 B5B5AC75FDCC85AACBDF747323AC5F7CA8D8FC482D03C848DEE4EFAD79F7CD50
  # '';
  # environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v6_zones_ts."0.e.1.a.c.5.1.1.a.7.d.f".name}.positive".text = ''
  #   ${lib.removeSuffix ".zone" reverse_v6_zones_ts."0.e.1.a.c.5.1.1.a.7.d.f".name}. IN DS 60960 15 2 DD09A9E95F7C7851FAC65FD39FDE55FAB2C001D5B37D744F98AA23C56FD63D16
  # '';
}
