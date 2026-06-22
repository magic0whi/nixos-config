lib:
let
  # TODO: use <hostName>.<nicName> = {
  #   ipv4 = [];
  #   ipv6 = [];
  # }
  hostAddrs = {
    # ============================================
    # Homelab's Physical Machines (TODO: Try KubeVirt)
    # ============================================
    Proteus-MBP14M4P = [
      {
        ipv4 = "100.95.17.39";
        ipv6 = "fd7a:115c:a1e0::783a:1127";
      }
      {
        ipv4 = "10.0.0.4";
        ipv6 = "fdfe:dcba:9877::4";
      }
    ];
    Proteus-NUC = [
      {
        ipv4 = "100.64.161.20";
        ipv6 = "fd7a:115c:a1e0::cd3a:a114";
        # Don't forget update the SOA Serial
        domains.CNAME = [
          "immich"
          "jellyfin"
          "paperless"
          "sb-nuc"
          "sunshine"
          "syncthing-nuc"
          "traefik-nuc"
          # "sftpgo"
        ];
      }
      {
        ipv4 = "10.0.0.2";
        ipv6 = "fdfe:dcba:9877::2";
      }
      { name = "enp46s0"; }
    ];
    Proteus-Desktop = [
      {
        ipv4 = "100.89.227.22";
        ipv6 = "fd7a:115c:a1e0::1a01:e318";
        domains = {
          A = [
            "@"
            "ns1"
          ];
          AAAA = [
            "@"
            "ns1"
          ];
          CNAME = [
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
          ];
        };
      }
      {
        ipv4 = "10.0.0.3";
        ipv6 = "fdfe:dcba:9877::3";
        domains = {
          A = [
            "@"
            "ns1"
          ];
          AAAA = [
            "@"
            "ns1"
          ];
        };
      }
      { name = "enp4s0"; }
      {
        name = "wlp0s20u9";
        priv_ipv4 = "192.168.12.1";
        ipv4_prefix_len = 24;
      }
    ];
    # ============================================
    # Other VMs and Physical Machines
    # ============================================
    Proteus-NixOS-0 = [
      {
        ipv4 = "100.68.75.16";
        ipv6 = "fd7a:115c:a1e0::683a:ad55";
      }
      {
        ipv4 = "10.0.0.1";
        ipv6 = "fdfe:dcba:9877::1";
      }
    ];
    Proteus-NixOS-1 = [
      {
        ipv4 = "100.121.95.98";
        ipv6 = "fd7a:115c:a1e0::df3a:5f62";
      }
      {
        ipv4 = "10.0.0.5";
        ipv6 = "fdfe:dcba:9877::5";
      }
    ];
    Proteus-NixOS-2 = [
      {
        ipv4 = "100.78.150.50";
        ipv6 = "fd7a:115c:a1e0::823a:9632";
      }
      {
        ipv4 = "10.0.0.6";
        ipv6 = "fdfe:dcba:9877::6";
      }
    ];
    Proteus-NixOS-3 = [
      {
        ipv4 = "100.113.250.94";
        ipv6 = "fd7a:115c:a1e0::703a:fa5e";
      }
      {
        ipv4 = "10.0.0.7";
        ipv6 = "fdfe:dcba:9877::7";
      }
    ];
    Proteus-NixOS-4 = [
      {
        ipv4 = "100.118.72.118";
        ipv6 = "fd7a:115c:a1e0::e33a:4876";
      }
      {
        ipv4 = "10.0.0.8";
        ipv6 = "fdfe:dcba:9877::8";
      }
    ];
    Proteus-NixOS-5 = [
      {
        ipv4 = "100.90.238.8";
        ipv6 = "fd7a:115c:a1e0::c53a:ee08";
      }
      {
        ipv4 = "10.0.0.9";
        ipv6 = "fdfe:dcba:9877::9";
      }
    ];
    Proteus-VF2 = [ { ipv4 = "192.168.1.26"; } ];
  };
in
{
  inherit hostAddrs;
  findHost =
    cn:
    lib.findFirst (
      hostname:
      lib.any (
        net:
        builtins.elem cn (net.domains.CNAME or [ ])
        || builtins.elem cn (net.domains.A or [ ])
        || builtins.elem cn (net.domains.AAAA or [ ])
      ) hostAddrs.${hostname}
    ) null (builtins.attrNames hostAddrs);
  caddyPort = 8080;

  soaSerial = 2026061002;
  knownHosts =
    let
      github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      proteus-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJla2bgFUIxlMyfqiS/BIxkFXFiIh4dhjjOvWzHnr6IL root@Proteus-Desktop";
    in
    {
      "github.com".public_key = github;
      "ssh.github.com".public_key = github;
      "codeberg.org".public_key =
        "codeberg.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
      Proteus-MBP14M4P.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC+ekT5jrD2KuLEqVeIASQ9A/VaBcrCE7xfcBqxsWbQ8";
      Proteus-NUC.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkreuZakzaKdfQL+YNAvcr6WRsIz5c3eoFcK3NAUmLu root@Proteus-NUC";
      Proteus-Desktop.public_key = proteus-desktop;
      "git.proteus.eu.org".public_key = proteus-desktop;
      Proteus-NixOS-0.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPzkXcoNKVwa5D6am4Bj5FVG+J/5NmsinoH53jrMRyk root@Proteus-NixOS-0";
      Proteus-NixOS-1.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8MZfS8gzTEb6sSBaLBALNabJ5sy1nBeNbiRzOo1Kyq root@Proteus-NixOS-1";
      Proteus-NixOS-2.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkal1+TGfarUm7uL4q4XdTTqKRtIlFo2pfsu04LoBFF root@Proteus-NixOS-2";
      Proteus-NixOS-3.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL3jAjZkkKHTUNqVf2ItJk2oObNDBiq8bylSF6f2Osi root@Proteus-NixOS-3";
      Proteus-NixOS-4.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvVGDKkAWK2gSnNB+dS8ie2WN5yzeH3/FQAiIXRZ1i8 root@Proteus-NixOS-4";
      Proteus-NixOS-5.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwHWbs4PsCW9Ji6Z4GepwjrXxhrD1DWGPdtNk9LdXwZ root@Proteus-NixOS-5";
      # Proteus-NixOS-6.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUXCE7Ghu4cLl0xBCg+q69QqGuhyIu17KDgrCpz0Gvb root@Proteus-NixOS-6";
    };

  syncthing = {
    desktop = {
      Proteus-MBP14M4P.id = "UF2KT6R-ISVDLBM-UJW3JKP-YZJTOES-7K55HS2-IGPE5MQ-OO4D6HK-LZRSLAE";
      Proteus-NUC.id = "3P2RWV6-RQMHBFS-L3Z5JTF-O6HOR66-7INJZNM-XW3WUSG-XCIB454-UITNPAF";
      Proteus-Desktop.id = "DFKVKXA-MHOUCDP-2DXEZGE-VUGGQXP-MRQCOZL-BOOBXAV-4IDSU26-B3GOUAF";
    };
    mobile = {
      LGE-AN00.id = "T2V6DJB-243NJGD-5B63LUP-DSLNFBD-U72KGD2-AZVTIHL-HEUMBTI-HAVD7A2";
      M2011K2C.id = "W6ZP2GU-HJ5DM7Q-UXKEKCI-OL3TYHM-LGLLPIN-3MCH7DM-76K3DB5-KNELIA5";
      "Redmi Note 5".id = "V3BFX3M-H4RJSCS-DZ6XQIM-3T5JK2V-KPYKGPD-HUV5UMG-PQA52BH-MYOFIAR";
    };
  };
}
