{
  # Services that uses Authelia as IAM, hosts have these subdomains will be allowed forwardedHeaders in Traefik
  oauthServices = [
    "git"
    "hass"
    "immich"
    "jellyfin"
    "nextcloud"
    "paperless"
    "papra"
    "plane"
  ];
  caddyPort = 8080;

  soaSerial = 2026062500;
  knownHosts =
    let
      github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      proteus-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJla2bgFUIxlMyfqiS/BIxkFXFiIh4dhjjOvWzHnr6IL root@Proteus-Desktop";
    in
    {
      "github.com" = github;
      "ssh.github.com" = github;
      "codeberg.org" = "codeberg.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
      Proteus-MBP14M4P = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC+ekT5jrD2KuLEqVeIASQ9A/VaBcrCE7xfcBqxsWbQ8";
      Proteus-NUC = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGkreuZakzaKdfQL+YNAvcr6WRsIz5c3eoFcK3NAUmLu root@Proteus-NUC";
      Proteus-Desktop = proteus-desktop;
      "git.proteus.eu.org" = proteus-desktop;
      Proteus-NixOS-0 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPzkXcoNKVwa5D6am4Bj5FVG+J/5NmsinoH53jrMRyk root@Proteus-NixOS-0";
      Proteus-NixOS-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8MZfS8gzTEb6sSBaLBALNabJ5sy1nBeNbiRzOo1Kyq root@Proteus-NixOS-1";
      Proteus-NixOS-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkal1+TGfarUm7uL4q4XdTTqKRtIlFo2pfsu04LoBFF root@Proteus-NixOS-2";
      Proteus-NixOS-3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILL3jAjZkkKHTUNqVf2ItJk2oObNDBiq8bylSF6f2Osi root@Proteus-NixOS-3";
      Proteus-NixOS-4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGvVGDKkAWK2gSnNB+dS8ie2WN5yzeH3/FQAiIXRZ1i8 root@Proteus-NixOS-4";
      Proteus-NixOS-5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBwHWbs4PsCW9Ji6Z4GepwjrXxhrD1DWGPdtNk9LdXwZ root@Proteus-NixOS-5";
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
