{
  hosts_addr = {
    # ============================================
    # Homelab's Physical Machines (TODO: Try KubeVirt)
    # ============================================
    Proteus-MBP14M4P = {
      ipv4 = "100.95.17.39";
      ipv6 = "fd7a:115c:a1e0::783a:1127";
      et_ipv4 = "10.0.0.4";
      et_ipv6 = "fdfe:dcba:9877::4";
    };
    Proteus-NUC = {
      ipv4 = "100.64.161.20";
      ipv6 = "fd7a:115c:a1e0::cd3a:a114";
      et_ipv4 = "10.0.0.2";
      et_ipv6 = "fdfe:dcba:9877::2";
      # Don't forget update the SOA Serial
      domains = {
        A = ["@" "ns1"];
        AAAA = ["@" "ns1"];
        CNAME = [
          "aria2"
          "atuin"
          "auth"
          "git"
          "hass"
          "immich"
          "ldap"
          "notebook"
          "paperless"
          "papra"
          "plane"
          "postgresql"
          "ql"
          "sb"
          # "sftpgo"
          "sunshine"
          "syncthing"
          "traefik"
        ];
      };
    };
    Proteus-Desktop = {
      ipv4 = "100.89.227.22";
      ipv6 = "fd7a:115c:a1e0::1a01:e318";
      et_ipv4 = "10.0.0.3";
      et_ipv6 = "fdfe:dcba:9877::3";
      iface = "enp4s0";
      iface_wlan = "wlp0s20u9";
      domains.CNAME = [
        "garage"
        "monero"
        "nextcloud"
        "sb-desktop"
        "syncthing-desktop"
        "s3"
        "*.s3"
        "s3-pub"
        "*.s3-pub"
        "traefik-desktop"
      ];
    };
    # ============================================
    # Other VMs and Physical Machines
    # ============================================
    Proteus-NixOS-0 = {
      ipv4 = "100.74.72.29";
      ipv6 = "fd7a:115c:a1e0::563a:481d";
      et_ipv4 = "10.0.0.1";
      et_ipv6 = "fdfe:dcba:9877::1";
    };
    Proteus-NixOS-1 = {
      ipv4 = "100.121.95.98";
      ipv6 = "fd7a:115c:a1e0::df3a:5f62";
      et_ipv4 = "10.0.0.5";
      et_ipv6 = "fdfe:dcba:9877::5";
    };
    Proteus-NixOS-2 = {
      ipv4 = "100.78.150.50";
      ipv6 = "fd7a:115c:a1e0::823a:9632";
      et_ipv4 = "10.0.0.6";
      et_ipv6 = "fdfe:dcba:9877::6";
    };
    Proteus-NixOS-3 = {
      ipv4 = "100.113.250.94";
      ipv6 = "fd7a:115c:a1e0::703a:fa5e";
      et_ipv4 = "10.0.0.7";
      et_ipv6 = "fdfe:dcba:9877::7";
    };
    Proteus-NixOS-4 = {
      ipv4 = "100.118.72.118";
      ipv6 = "fd7a:115c:a1e0::e33a:4876";
      et_ipv4 = "10.0.0.8";
      et_ipv6 = "fdfe:dcba:9877::8";
    };
    Proteus-NixOS-5 = {
      ipv4 = "100.90.238.8";
      ipv6 = "fd7a:115c:a1e0::c53a:ee08";
      et_ipv4 = "10.0.0.9";
      et_ipv6 = "fdfe:dcba:9877::9";
    };
    # Proteus-NixOS-6.ipv4 = "100.126.174.68";
    # Orange Pi 5 - ARM
    # RJ45 port 1 - enP4p65s0
    # RJ45 port 2 - enP3p49s0
    rakushun = {
      iface = "enP4p65s0";
      ipv4 = "192.168.5.179";
    };
    suzi = {
      iface = "enp2s0"; # fake iface, it's not used by the host
      ipv4 = "192.168.5.178";
    };
    # ============================================
    # Kubernetes Clusters
    # ============================================
    k3s-prod-1-master-1 = {
      iface = "enp2s0";
      ipv4 = "192.168.5.108";
    }; # VM
    k3s-prod-1-worker-1 = {
      iface = "enp2s0";
      ipv4 = "192.168.5.111";
    }; # VM
    k3s-test-1-master-1 = {
      iface = "enp2s0";
      ipv4 = "192.168.5.114";
    }; # KubeVirt VM
  };
  known_hosts = let
    github_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  in {
    "github.com".public_key = github_key;
    "ssh.github.com".public_key = github_key;
    Proteus-MBP14M4P = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC+ekT5jrD2KuLEqVeIASQ9A/VaBcrCE7xfcBqxsWbQ8";
      syncthing_id = "UF2KT6R-ISVDLBM-UJW3JKP-YZJTOES-7K55HS2-IGPE5MQ-OO4D6HK-LZRSLAE";
    };
    Proteus-NUC = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkreuZakzaKdfQL+YNAvcr6WRsIz5c3eoFcK3NAUmLu root@Proteus-NUC";
      syncthing_id = "3P2RWV6-RQMHBFS-L3Z5JTF-O6HOR66-7INJZNM-XW3WUSG-XCIB454-UITNPAF";
    };
    Proteus-Desktop = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJla2bgFUIxlMyfqiS/BIxkFXFiIh4dhjjOvWzHnr6IL root@Proteus-Desktop";
      syncthing_id = "DFKVKXA-MHOUCDP-2DXEZGE-VUGGQXP-MRQCOZL-BOOBXAV-4IDSU26-B3GOUAF";
    };
    Proteus-NixOS-0.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqgfVyb6hCdQmzbls0NNjMJ6Zxp3zq+XClR1OZIPnCD root@Proteus-NixOS-1";
    Proteus-NixOS-1.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8MZfS8gzTEb6sSBaLBALNabJ5sy1nBeNbiRzOo1Kyq root@Proteus-NixOS-1";
    Proteus-NixOS-2.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkal1+TGfarUm7uL4q4XdTTqKRtIlFo2pfsu04LoBFF root@Proteus-NixOS-2";
    Proteus-NixOS-3.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL3jAjZkkKHTUNqVf2ItJk2oObNDBiq8bylSF6f2Osi root@Proteus-NixOS-3";
    Proteus-NixOS-4.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvVGDKkAWK2gSnNB+dS8ie2WN5yzeH3/FQAiIXRZ1i8 root@Proteus-NixOS-4";
    Proteus-NixOS-5.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwHWbs4PsCW9Ji6Z4GepwjrXxhrD1DWGPdtNk9LdXwZ root@Proteus-NixOS-5";
    # Proteus-NixOS-6.public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUXCE7Ghu4cLl0xBCg+q69QqGuhyIu17KDgrCpz0Gvb root@Proteus-NixOS-6";
  };
}
