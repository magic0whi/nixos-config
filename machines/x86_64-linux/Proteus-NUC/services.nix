{
  lib,
  pkgs,
  ...
}: {
  networking.firewall = {
    allowedTCPPorts = [
      5201
      5201 # iperf3
      22000 # Syncthing TCP transfers
      53317 # LocalSend (HTTP/TCP)
    ];
    allowedUDPPorts = [
      5201 # iperf3
      21027 # Syncthing discovery broadcasts on IPv4 and multicasts on IPv6
      22000 # Syncthing QUIC transfers
      53317 # LocalSend (Multicast/UDP)
    ];
  };
  ## BEGIN services_tor.nix
  services.tor = {
    enable = true;
    client.enable = true;
    # openFirewall = true;
    settings = {
      # ExitNodes = "{GB}";
      ExitPolicy = ["accept *:*"];
      AvoidDiskWrites = 1;
      HardwareAccel = 1;
      UseBridges = true;
      ClientTransportPlugin = "snowflake exec ${lib.getExe' pkgs.snowflake "client"} -url https://snowflake-broker.azureedge.net/ -front ajax.aspnetcdn.com -ice stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn -log /tmp/snowflake-client.log";
      Bridge = [
        "snowflake 192.0.2.3:80 2B280B23E1107BB62ABFC40DDCC8824814F80A72 fingerprint=2B280B23E1107BB62ABFC40DDCC8824814F80A72 url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.com:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn"
        "snowflake 192.0.2.4:80 8838024498816A039FCBBAB14E6F40A0843051FA fingerprint=8838024498816A039FCBBAB14E6F40A0843051FA url=https://1098762253.rsc.cdn77.org/ fronts=www.cdn77.com,www.phpmyadmin.net ice=stun:stun.l.google.com:19302,stun:stun.antisip.com:3478,stun:stun.bluesip.net:3478,stun:stun.dus.net:3478,stun:stun.epygi.com:3478,stun:stun.sonetel.net:3478,stun:stun.uls.co.za:3478,stun:stun.voipgate.com:3478,stun:stun.voys.nl:3478 utls-imitate=hellorandomizedalpn"
      ];
    };
  };
  ## END services_tor.nix
}
