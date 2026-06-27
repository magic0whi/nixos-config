{
  lib,
  nixosConfigurations,
  darwinConfigurations,
  mylib,
  ...
}:
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

  soaSerial = 2026062600;
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

  allHostAddrs =
    (lib.evalModules {
      modules = [
        (
          { config, lib, ... }:
          import (mylib.relativeToRoot "modules/variables/host-addrs.nix") {
            inherit config lib;
            isGlobal = true;
          }
        )
        {
          config.vars.hostAddrs = lib.mkMerge (
            lib.mapAttrsToList (name: host: {
              ${name} = host.config.vars.hostAddrs.${name} or { };
            }) (nixosConfigurations // darwinConfigurations)
          );
        }
      ];
    }).config.vars.hostAddrs;
}
