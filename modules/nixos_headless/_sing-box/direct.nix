# Shoud put before FakeIP; Clash Mode
{ lib, mylib, ... }:
let
  out = "Direct";
  direct_process.rules = [
    # Tor & I2P
    {
      process_name = [
        "snowflake-pt-client"
        "snowflake-client.exe"
        "i2pd"
        "tor"
        "tor.exe"
      ];
    }
    { process_path_regex = [ ".*snowflake.*" ]; }

    # DNS utils
    { process_name = [ "doggo" ]; }

    # Docker { 172.16.0.0-172.18.255.255, 172.19.0.4-172.31.255.255 }
    {
      ip_cidr = [
        "172.16.0.0/15"
        "172.19.0.4/30"
        "172.19.0.8/29"
        "172.19.0.16/28"
        "172.19.0.32/27"
        "172.19.0.64/26"
        "172.19.0.128/25"
        "172.19.1.0/24"
        "172.19.2.0/23"
        "172.19.4.0/22"
        "172.19.8.0/21"
        "172.19.16.0/20"
        "172.19.32.0/19"
        "172.19.64.0/18"
        "172.19.128.0/17"
        "172.20.0.0/14"
        "172.24.0.0/13"
      ];
    }
    # Misc
    {
      process_name = [
        "aria2c"
        "monerod"
        "syncthing"
        "syncthing.exe"
      ];
    }
  ];
  rules = [ { domain_suffix = [ "syncthing.net" ]; } ];
in
{
  dns.rules = lib.mkBefore (mylib.mkSbRules true out rules);
  route.rules = lib.mkMerge (
    let
      mkSbRules = mylib.mkSbRules false;
    in
    [
      (lib.mkBefore (mkSbRules out direct_process.rules))
      (lib.mkOrder 875 (mkSbRules out rules))
    ]
  );
}
