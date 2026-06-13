{ sharedDnsServerCfg, ... }:
{
  dns.servers =
    (map
      (
        tag:
        sharedDnsServerCfg
        // {
          inherit tag;
          detour = tag;
        }
      )
      [
        "Germany"
        "HongKong"
        "UnitedKingdom"
        "UnitedStates"
        "Klarna"
        "AI"
        "Apple"
        "Games"
        "Google"
        "Meta"
        "Microsoft"
        "Oracle"
      ]
    )
    ++ [
      {
        tag = "category-speedtest";
        detour = "Category-Speedtest";
        domain_resolver = "bootstrap";
        type = "tls";
        server = "dns.alidns.com";
      }
    ];
}
