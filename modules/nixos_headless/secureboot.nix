{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  # This makes sbctl requires `--disable-landlock` to work
  sops.secrets = {
    "secureboot_PK.key" = {
      sopsFile = "${myvars.secretsDir}/secureboot_PK.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/PK/PK.key";
      format = "binary";
    };
    "secureboot_KEK.key" = {
      sopsFile = "${myvars.secretsDir}/secureboot_KEK.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/KEK/KEK.key";
      format = "binary";
    };
    "secureboot_db.key" = {
      sopsFile = "${myvars.secretsDir}/secureboot_db.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/db/db.key";
      format = "binary";
    };
  };
  systemd.tmpfiles.settings = {
    "01-secureboot-GUID"."${config.boot.lanzaboote.pkiBundle}/GUID"."L+".argument = "${myvars.secretsDir}/secureboot_GUID";
    "01-secureboot-PK-key"."${config.boot.lanzaboote.pkiBundle}/keys/PK/PK.pem"."L+".argument =
      "${myvars.secretsDir}/secureboot_PK.pem";
    "01-secureboot-KEK-key"."${config.boot.lanzaboote.pkiBundle}/keys/KEK/KEK.pem"."L+".argument =
      "${myvars.secretsDir}/secureboot_KEK.pem";
    "01-secureboot-db-key"."${config.boot.lanzaboote.pkiBundle}/keys/db/db.pem"."L+".argument =
      "${myvars.secretsDir}/secureboot_db.pem";
  };

  environment.systemPackages = [ pkgs.sbctl ]; # For debugging and troubleshooting Secure Boot.
  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix generated at installation time. So we force it to false for now.
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl"; # If don't have keys yet, run `sudo sbctl create-keys`
    # Supress unsigned error, useful if run NixOS in installation media, or sops-nix don't decrypted sb keys yet
    # allowUnsigned = true;
    autoEnrollKeys.enable = lib.mkDefault true;
  };
}
