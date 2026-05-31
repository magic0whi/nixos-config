{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "traffic-quota-module-test";
  meta.maintainers = [ "Proteus Qian" ];

  # Define the VM's configuration
  nodes =
    let
      shared_cfg = {
        imports = [ ../modules/nixos_headless/traffic-quota.nix ];
        services.trafficQuota.enable = true;
      };
    in
    {
      machine_normal = {
        imports = [ shared_cfg ];
        services.trafficQuota.limit = 196;
      };
      machine_exceeded = {
        imports = [ shared_cfg ];
        services.trafficQuota.limit = 0;
      };
    };

  # interactive.sshBackdoor.enable = true;

  # Python script to interact with the VM
  testScript = ''
    start_all()

    for machine in [machine_normal, machine_exceeded]:
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("vnstat.service")
        machine.wait_for_unit("traffic-quota.timer")

    for machine in [machine_normal, machine_exceeded]:
        machine.execute("systemctl start traffic-quota.service")

    with subtest("Normal machine: executes successfully without shutting down"):
        machine_normal.succeed("systemctl is-active multi-user.target")

    with subtest("Exceeded machine: automatically powers off when limit is breached"):
        machine_exceeded.wait_for_shutdown()
  '';
}
