{
  lib,
  nixosConfigurations,
  darwinConfigurations,
  mylib,
  ...
}:
let
  custom_module =
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
        (
          { config, ... }:
          {
            options.utils = {
              findFirstHostBySubdomain = lib.mkOption {
                type = with lib.types; functionTo (nullOr str);
                default =
                  sub:
                  lib.findFirst (
                    hostname:
                    lib.any (nic: builtins.elem sub nic.subdomains.A || builtins.elem sub nic.subdomains.AAAA) (
                      builtins.attrValues config.vars.hostAddrs.${hostname}
                    )
                  ) null (builtins.attrNames config.vars.hostAddrs);
                description = ''
                  Function that returns the first hostname containing the specified subdomain, or null if not found.
                '';
                readOnly = true;
              };
              findAllHostContains = lib.mkOption {
                type = with lib.types; functionTo (nullOr (listOf str));
                default =
                  sub:
                  builtins.filter (
                    hostname:
                    lib.any (
                      nic: lib.any (a: lib.hasInfix sub a) nic.subdomains.A || lib.any (aaaa: lib.hasInfix sub aaaa) nic.subdomains.AAAA
                    ) (builtins.attrValues config.vars.hostAddrs.${hostname})
                  ) (builtins.attrNames config.vars.hostAddrs);
                description = ''
                  Function that returns the all the hostname containing the specified keyword in subdomains.
                '';
                readOnly = true;
              };
            };
          }
        )
      ];
    }).config;
in
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

    # find all contains
    "exporter"
  ];
  caddyPort = 8080;

  soaSerial = 2026071200;
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
      Proteus-NixOS-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII80bJtMayIRRUVSkiGOXYLteLvklt87+kMymtdGf5uG root@Proteus-NixOS-1";
      Proteus-NixOS-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBYHi5EXmmmJ+mRbkXM1qmVVv6FYbSG6OGH6rW43nesr root@Proteus-NixOS-2";
      Proteus-NixOS-3 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVIYeCYLxcDtTh2AlwLYhCVPE5FT5onV5GkBvDv3i07 root@Proteus-NixOS-3";
      Proteus-NixOS-4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGz6g8PDGhRYZBPMRyA6yvQCg9EQQl7RpOXcBCIVomBR root@Proteus-NixOS-4";
      Proteus-NixOS-5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvuXbtrJj9rwmg7addReGIDP/MgK6h5vtLjsykb/RCg root@Proteus-NixOS-5";
    };

  allHostAddrs = custom_module.vars.hostAddrs;
  inherit (custom_module.utils) findFirstHostBySubdomain findAllHostContains;

  libvirtNetCidr = "192.168.122.0/24";
}
