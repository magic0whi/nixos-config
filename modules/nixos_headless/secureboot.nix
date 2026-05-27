{
  config,
  myvars,
  pkgs,
  ...
}:
{
  sops.secrets = {
    "secureboot_PK.key" = {
      sopsFile = "${myvars.secrets_dir}/secureboot_PK.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/PK/PK.key";
      format = "binary";
    };
    "secureboot_KEK.key" = {
      sopsFile = "${myvars.secrets_dir}/secureboot_KEK.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/KEK/KEK.key";
      format = "binary";
    };
    "secureboot_db.key" = {
      sopsFile = "${myvars.secrets_dir}/secureboot_db.key.sops";
      path = "${config.boot.lanzaboote.pkiBundle}/keys/db/db.key";
      format = "binary";
    };
  };
  systemd.tmpfiles.settings = {
    "01-secureboot-PK-key"."${config.boot.lanzaboote.pkiBundle}/keys/PK/PK.pem"."L+".argument =
      "${myvars.secrets_dir}/secureboot_PK.pem";
    "01-secureboot-KEK-key"."${config.boot.lanzaboote.pkiBundle}/keys/KEK/KEK.pem"."L+".argument =
      "${myvars.secrets_dir}/secureboot_KEK.pem";
    "01-secureboot-db-key"."${config.boot.lanzaboote.pkiBundle}/keys/db/db.pem"."L+".argument =
      "${myvars.secrets_dir}/secureboot_db.pem";
  };

  environment.systemPackages = [ pkgs.sbctl ]; # For debugging and troubleshooting Secure Boot.
  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix generated at installation time. So we force it to false for now.
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl"; # sudo sbctl create-keys
    # allowUnsigned = true; # Useful for first boot
    autoEnrollKeys.enable = true;
  };
}
