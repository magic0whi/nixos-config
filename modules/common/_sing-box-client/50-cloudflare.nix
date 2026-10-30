{
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  out = "Cloudflare IP";
in
{
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "Direct";
    }
  );
  route = {
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geoip-cloudflare";
          url = "${urlPrefix}/geo/geoip/cloudflare.srs";
        }
      ];
    rules = lib.mkBefore (mylib.mkSbRules false out [ { rule_set = [ "geoip-cloudflare" ]; } ]);
  };
}
