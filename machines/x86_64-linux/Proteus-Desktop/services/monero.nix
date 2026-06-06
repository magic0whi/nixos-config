{
  myvars,
  config,
  ...
}:
{
  systemd.services.monero.unitConfig.RequiresMountsFor = [ myvars.storagePath ];
  services.monero = {
    enable = true;
    dataDir = "${myvars.storagePath}/monero";
    extraConfig = ''
      # log-file=${config.services.monero.dataDir}/monero.log
      # log-level=0
      p2p-use-ipv6=1
      rpc-use-ipv6=1
      public-node=1
      confirm-external-bind=1
      rpc-bind-ipv6-address=fd7a:115c:a1e0::d901:e013
    '';
    prune = true;
    rpc.address = "0.0.0.0";
    rpc.restricted = true; # restrict RPC to view only commands (`restricted-rpc`)
  };
}
