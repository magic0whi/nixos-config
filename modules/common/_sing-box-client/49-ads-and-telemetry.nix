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

  out = "AdsAndTelemetry";
  rules = [
    {
      domain_suffix = [
        "appcues.com" # Appcues product tours
        "appcues.net" # Appcues API / websocket
        "birdie.so" # Birdie support widget
        "browser-intake-datadoghq.eu" # Datadog EU RUM / logs intake
        "bugsnag.com" # Bugsnag: error + session telemetry
        "datadoghq.com" # Datadog: RUM / logs / crash reports
        "heap-api.com" # Heap ingest
        "heapanalytics.com" # Heap analytics
        "honeycomb.io" # Honeycomb telemetry
        "hs-analytics.net" # HubSpot analytics
        "mixpanel.com" # product analytics
        "onmaven.app" # Maven support chat
        "sentry-cdn.com" # Sentry JS SDK CDN
        "sentry10.bynder.cloud" # Bynder Sentry: error + CSP report ingest
      ];
    }
    { rule_set = [ "geosite-ads-and-telemetry" ]; }
  ];
in
{
  dns = {
    servers = lib.singleton (
      dnsServerCfg.direct
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
      default = "Direct";
    }
  );
  route = {
    rules = lib.mkOrder sniff_pri (mylib.mkSbRules false out rules);
    rule_set = map (rule_set: ruleSetCfg.defaultCfg // rule_set) [
      {
        tag = "geosite-ads-and-telemetry";
        url = "${ruleSetCfg.urlPrefix}/geo/geosite/category-ads-and-telemetry.srs";
      }
    ];
  };
}
