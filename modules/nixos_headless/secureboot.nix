{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  # This makes sbctl requires `--disable-landlock` to work
  sops.secrets = {
    "secureboot_PK.key" = {
      sopsFile = const.secretsDir + "/secureboot/PK.key.sops";
      path = config.boot.lanzaboote.pkiBundle + "/keys/PK/PK.key";
      format = "binary";
    };
    "secureboot_KEK.key" = {
      sopsFile = const.secretsDir + "/secureboot/KEK.key.sops";
      path = config.boot.lanzaboote.pkiBundle + "/keys/KEK/KEK.key";
      format = "binary";
    };
    "secureboot_db.key" = {
      sopsFile = const.secretsDir + "/secureboot/db.key.sops";
      path = config.boot.lanzaboote.pkiBundle + "/keys/db/db.key";
      format = "binary";
    };
  };
  systemd.tmpfiles.settings = {
    "01-secureboot-GUID"."${config.boot.lanzaboote.pkiBundle}/GUID"."L+".argument = toString (
      pkgs.writeText "secureboot_GUID" "29fd7ac6-d1a3-4043-9f87-fe35fcb6b679"
    );
    "01-secureboot-PK-key"."${config.boot.lanzaboote.pkiBundle}/keys/PK/PK.pem"."L+".argument = toString (
      const.secretsDir + "/secureboot/PK.pem"
    );
    "01-secureboot-KEK-key"."${config.boot.lanzaboote.pkiBundle}/keys/KEK/KEK.pem"."L+".argument = toString (
      const.secretsDir + "/secureboot/KEK.pem"
    );
    "01-secureboot-db-key"."${config.boot.lanzaboote.pkiBundle}/keys/db/db.pem"."L+".argument = toString (
      const.secretsDir + "/secureboot/db.pem"
    );
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
