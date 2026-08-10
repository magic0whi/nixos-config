{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sing-box.generateMobileConfig;
  utils = import "${pkgs.path}/nixos/lib/utils.nix" { inherit config lib pkgs; };
  path = "/run/sing-box/mobile";
in
{
  config = lib.mkIf cfg.enable {
    # TIP: After provision you can manually process with sing-box-subscribe
    systemd.services.sing-box.serviceConfig.ExecStartPre = [
      # Generate alter config.json for mobile devices
      # NOTE: sing-box will treat all the *.json in the working directory as splitted config
      "+-${pkgs.writeShellScript "sing-box-gen-mobile-config" ''
        set -euo pipefail
        mkdir -p ${path}
        ${utils.genJqSecretsReplacementSnippet cfg.mobile "${path}/mobile.json"}
        chown --reference=/run/sing-box ${path}/mobile.json
      ''}"
      # Generate alter config.json for rooted mobile devices
      "+-${pkgs.writeShellScript "sing-box-gen-root-mobile-config" ''
        set -euo pipefail
        mkdir -p ${path}
        ${utils.genJqSecretsReplacementSnippet cfg.root "${path}/root.json"}
        chown --reference=/run/sing-box ${path}/root.json
      ''}"
    ];
  };
}
