{
  services.howdy = {
    enable = true;
    # Default "required". Set "sufficient" to allow unlocks directly; the
    # password prompt remains as fallback.
    control = "sufficient"; # Default "required"
  };

  # Polkit PAM authentication runs in polkit-agent-helper@.service, whose
  # upstream unit sets PrivateDevices=yes and only allows /dev/null.
  # Ref: https://github.com/NixOS/nixpkgs/issues/483867#issuecomment-3897207420
  systemd.services."polkit-agent-helper@".serviceConfig = {
    # The real device nodes cannot be re-added by DeviceAllow, so PrivateDevices
    # must be disabled; DevicePolicy=strict still limits access to the listed nodes.
    PrivateDevices = false;
    DeviceAllow = [ "/dev/video2 rw" ];
  };

  # If enrollment or unlocking reports black frames in dim rooms, enable the
  # IR emitter, then run `sudo linux-enable-ir-emitter configure` once:
  # services.linux-enable-ir-emitter = {
  #   enable = true;
  #   device = "video2";
  # };
}
