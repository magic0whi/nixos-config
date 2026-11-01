{
  const,
  dnsServerCfg,
  lib,
  mylib,
  ruleSetCfg,
  selectorCfg,
  ...
}:
let
  pri = 0.49;
  fakeip_pri = pri * (2000 - const.sb.dnsFakeIpPri) + const.sb.dnsFakeIpPri;
  sniff_pri = pri * (2000 - const.sb.routeSniffPri) + const.sb.routeSniffPri;

  out = "AI";
  rules = [
    { domain = "gspe1-ssl.ls.apple.com"; }
    {
      rule_set = [
        "geosite-anthropic"
        "geosite-apple-intelligence"
        "geosite-bing"
        "geosite-github-copilot" # NOTE: must before Microsoft rules
        "geosite-openai"
        "geosite-perplexity"
        "geosite-xai"
        "geosite-google-gemini"
      ];
    }
  ];
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.default
      // {
        tag = out;
        detour = out;
      }
    );
    rules = lib.mkOrder fakeip_pri (mylib.mkSbRules true out rules);
  };
  outbounds = lib.singleton (
    selectorCfg
    // {
      tag = out;
      default = "UnitedStates";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set =
      let
        inherit (ruleSetCfg) urlPrefix defaultCfg;
      in
      map (rule_set: defaultCfg // rule_set) [
        {
          tag = "geosite-anthropic";
          url = "${urlPrefix}/geo/geosite/anthropic.srs";
        }
        {
          tag = "geosite-apple-intelligence";
          url = "${urlPrefix}/geo/geosite/apple-intelligence.srs";
        }
        {
          tag = "geosite-bing";
          url = "${urlPrefix}/geo/geosite/bing.srs";
        }
        {
          tag = "geosite-github-copilot";
          url = "${urlPrefix}/geo/geosite/github-copilot.srs";
        }
        {
          tag = "geosite-openai";
          url = "${urlPrefix}/geo/geosite/openai.srs";
        }
        {
          tag = "geosite-perplexity";
          url = "${urlPrefix}/geo/geosite/perplexity.srs";
        }
        {
          tag = "geosite-xai";
          url = "${urlPrefix}/geo/geosite/xai.srs";
        }
        {
          tag = "geosite-google-gemini";
          url = "${urlPrefix}/geo/geosite/google-gemini.srs";
        }
      ];
  };
}
