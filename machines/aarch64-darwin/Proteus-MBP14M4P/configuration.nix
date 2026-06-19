{
  config,
  const,
  ...
}:
{
  sops.secrets."sb_client_darwin.json" = {
    sopsFile = "${const.secretsDir}/sb_client_darwin.json.sops";
    format = "binary";
    # NOTE: As of 2026-05-05, sops-nix don't support restartUnits on macOS
    # restartUnits = ["sing-box.service"];
  };
  services.sing-box = {
    enable = true;
    settings = {
      _secret = config.sops.secrets."sb_client_darwin.json".path;
      quote = false;
    };
  };
  # launchd.daemons.tailscaled.serviceConfig = {
  #   StandardErrorPath = "/Library/Logs/com.tailscale.ipn.stderr.log";
  #   StandardOutPath = "/Library/Logs/com.tailscale.ipn.stdout.log";
  # };
}
