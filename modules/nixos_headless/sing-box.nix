{
  config,
  lib,
  ...
}: {
  # Use camel case for outside interface
  options.services.sing-box.configFile = lib.mkOption {
    type = lib.types.path;
    description = "Path to the sing-box config file";
  };
  config = lib.mkIf config.services.sing-box.enable {
    # Override the sing-box's systemd service
    systemd.services.sing-box.serviceConfig = {
      LoadCredential = [("config.json:" + config.services.sing-box.configFile)];
      ExecStart = [
        "" # Empty value remove previous value
        (let
          configArgs = "-c $\{CREDENTIALS_DIRECTORY}/config.json";
        in "${lib.getExe config.services.sing-box.package} -D \${STATE_DIRECTORY} ${configArgs} run")
      ];
    };
  };
}
