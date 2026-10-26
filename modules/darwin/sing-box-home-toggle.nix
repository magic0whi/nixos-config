{
  config,
  lib,
  ...
}:
let
  home_lan_prefixes = [
    "192.168.10."
    "192.168.15."
  ];
  label = config.launchd.daemons.sing-box.serviceConfig.Label;
  plist = "/Library/LaunchDaemons/${label}.plist";
in
lib.mkIf config.services.sing-box.enable {
  launchd.daemons.sing-box-home-toggle = {
    script = ''
      set -euo pipefail

      AT_HOME=0
      for iface in $(/sbin/ifconfig -l); do
        router=$(/usr/sbin/ipconfig getoption "$iface" router 2>/dev/null) || continue
        case "$router" in
          # e.g. 192.168.10.*|192.168.15.*) AT_HOME=1 ;;
          ${lib.concatMapStringsSep "|" (p: "${p}*") home_lan_prefixes}) AT_HOME=1 ;;
        esac
      done

      if /bin/launchctl print system/${label} >/dev/null 2>&1; then loaded=1; else loaded=0; fi
      if [ "$AT_HOME" = 1 ] && [ "$loaded" = 1 ]; then
        echo "$(date): at home, stopping sing-box"
        /bin/launchctl bootout system/${label}
      elif [ "$AT_HOME" = 0 ] && [ "$loaded" = 0 ]; then
        echo "$(date): outside, starting sing-box"
        /bin/launchctl bootstrap system ${plist}
      fi
    '';
    serviceConfig = {
      RunAtLoad = true;
      # Re-run on network changes, poll as a fallback
      WatchPaths = [
        "/var/run/resolv.conf"
        "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
      ];
      StartInterval = 60;
      StandardOutPath = "/Library/Logs/sing-box-home-toggle.log";
      StandardErrorPath = "/Library/Logs/sing-box-home-toggle.log";
    };
  };
}
