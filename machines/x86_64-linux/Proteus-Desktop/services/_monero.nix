{
  const,
  config,
  ...
}:
let
  hostname = config.networking.hostName;
in
{
  sops.secrets."monero_server.priv.pem" = {
    restartUnits = [ "monero.service" ];
    sopsFile = "${const.secretsDir}/proteus_server.priv.pem.sops";
    format = "binary";
    owner = config.systemd.services.monero.serviceConfig.User;
  };

  networking.firewall.allowedTCPPorts = [
    18080 # p2p-bind-port
    config.services.monero.rpc.port
  ];

  vars.hostAddrs.${config.networking.hostName} =
    let
      subdomains = {
        A = [ "monero" ];
        AAAA = [ "monero" ];
      };
    in
    {
      tailscale = { inherit subdomains; };
      easytier = { inherit subdomains; };
    };
  systemd.services.monero.unitConfig.RequiresMountsFor = [ const.storagePath ];
  services.monero = {
    enable = true;
    dataDir = "${const.storagePath}/monero";
    extraConfig = ''
      # Centralized services
      check-updates=disabled
      # Block known malicious nodes. The DNS blocklist is centrally managed by Monero contributors.
      enable-dns-blocklist=1

      # log-file=${config.services.monero.dataDir}/monero.log
      # log-level=0
      p2p-use-ipv6=1
      public-node=1

      # RPC
      rpc-use-ipv6=1
      # confirm-external-bind=1
      # rpc-bind-ipv6-address=${config.vars.hostAddrs.${hostname}.easytier.ipv6NoCidr}
      rpc-restricted-bind-ip=0.0.0.0
      rpc-restricted-bind-ipv6-address=::
      rpc-restricted-bind-port=18081
      rpc-ssl=enabled # Force TLS on RPC connections
      rpc-ssl-private-key=${config.sops.secrets."monero_server.priv.pem".path}
      rpc-ssl-certificate=${const.secretsDir}/proteus_server.pub.pem
    '';
    prune = true; # Pruning saves 2/3 of disk space w/o degrading functionality but contributes less to the network
    rpc = {
      # address = config.vars.hostAddrs.${hostname}.easytier.ipv4NoCidr;
      # restricted = true; # restrict RPC to view only commands (`restricted-rpc`)
      port = 18083;
    };
  };
}
