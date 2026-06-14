{
  config,
  pkgs,
  ...
}:
{
  services.sing-box.generateConfig.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime-legacy1
  ];
  environment.systemPackages = with pkgs; [ bpftrace ]; # powerful tracing tool, ref: https://github.com/bpftrace/bpftrace
  ## BEGIN iwd.nix
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings.General.Country = "US";
  systemd.services.iwd.serviceConfig.ExecStart = [
    # Leave an empty string to remove previous ExecStarts
    ""
    "${config.networking.wireless.iwd.package}/libexec/iwd --nointerfaces 'wlan[0-9]'"
  ];
  systemd.network.links."80-iwd".enable = false; # Or
  # environment.etc."systemd/network/80-iwd.link".source = lib.mkForce (mylib.mkOutOfStoreSymlink "/dev/null");
  ## END iwd.nix
  ## START thunderbolt.nix
  services.hardware.bolt.enable = true;
  ## END thunderbolt.nix
}
