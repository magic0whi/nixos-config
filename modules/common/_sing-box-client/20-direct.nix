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

    # Misc
    {
      process_name = [
        "aria2c"
        "monerod"
        "syncthing"
        "syncthing.exe"
      ];
    }
    { process_path_regex = [ ".*localsend.*" ]; }
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
