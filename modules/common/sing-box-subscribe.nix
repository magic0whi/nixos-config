# TODO: split to a standaline flake
{ lib, pkgs, ... }:
{
  options.services.sing-box.subscribe = {
    enable = lib.mkEnableOption "Whether enable sing-box-subscribe.";
    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
      description = "contents to be written to providers.json.";
    };
    src = lib.mkOption {
      type = lib.types.path;
      default = pkgs.fetchFromGitHub {
        owner = "Toperlock";
        repo = "sing-box-subscribe";
        rev = "9b94f3e61d1a14e6eca228df189ada8719ca9174";
        hash = "sha256-MvjoAL4wZxIR37B08ViPcdvXN+OFwn+TV1qf2Boe4Nw=";
      };
      description = "Fetched sing-box-subscribe source.";
    };
    pythonEnv = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python3.withPackages (
        ps: with ps; [
          requests
          paramiko
          scp
          ruamel-yaml
          chardet
          pyyaml
          flask
        ]
      );
      description = "Python environment package containing required dependencies.";
    };
    updateInterval = lib.mkOption {
      type = lib.types.int;
      default = 60 * 60 * 24 * 7;
      description = "Update interval in seconds";
    };
  };
}
