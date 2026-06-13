# After FakeIP; Clash Mode
{
  lib,
  mylib,
  sharedSelectorCfg,
  ...
}:
let
  # Use list because sort matter
  super_rules = [
    {
      out = "VoWiFi";
      rules = lib.singleton {
        domain_suffix = [
          "3gppnetwork.org"
          "jibecloud.net"
          "ee.co.uk"
          "hkcsl.com"
        ];
      };
    }
    {
      out = "PayPal";
      rules = [
        { domain_suffix = "marqeta.com"; }
        { rule_set = "geosite-paypal"; }
      ];
    }
    {
      out = "HSBC";
      rules = [
        { domain_suffix = "checkfreeweb.com"; } # HSBC US Bank-to-Bank
        { rule_set = "geosite-hsbc"; }
      ];
    }
    {
      out = "Kraken";
      rules = lib.singleton { rule_set = "geosite-kraken"; };
    }
    {
      out = "OKX";
      rules = [
        {
          domain_suffix = [
            "okcoin.com"
            "okx.ac"
            "okx.cab"
          ];
        }
        { rule_set = "geosite-okx"; }
      ];
    }
    {
      out = "Trading212";
      rules = lib.singleton {
        domain_regex = "trading212equities\\.s3\\.\\S+\\.amazonaws\\.com";
        domain_suffix = "trading212.com";
      };
    }
    {
      out = "SumUp";
      rules = lib.singleton {
        domain_suffix = [
          "sumup.com"
          "sumup.io"
          "sumup.net"
        ];
      };
    }
    {
      out = "CurvePay";
      rules = lib.singleton {
        domain_suffix = [
          "curve.app"
          "curve.com"
          "curve.api.kustomerapp.com"
          "imaginecurve.com"
        ];
      };
    }
  ];
in
{
  dns = {
    servers =
      let
        def_cfg = {
          server = "8.8.8.8";
          type = "tls";
        };
      in
      map
        (
          tag:
          def_cfg
          // {
            inherit tag;
            detour = tag;
          }
        )
        [
          "VoWiFi"
          "PayPal"
          "HSBC"
          "Kraken"
          "OKX"
          "Trading212"
          "SumUp"
          "CurvePay"
        ];
    rules = lib.mkAfter (lib.flatten (map (rules: mylib.mkSbRules true rules.out rules.rules) super_rules));
  };
  outbounds = lib.mkAfter (
    map (selector: sharedSelectorCfg // selector) [
      {
        tag = "VoWiFi";
        default = "Default";
      }
      {
        tag = "PayPal";
        default = "UnitedKingdom";
      }
      {
        tag = "HSBC";
        default = "Direct";
      }
      {
        tag = "Kraken";
        default = "UnitedKingdom";
      }
      {
        tag = "OKX";
        default = "Default";
      }
      {
        tag = "Trading212";
        default = "UnitedKingdom";
      }
      {
        tag = "SumUp";
        default = "UnitedKingdom";
      }
      {
        tag = "CurvePay";
        default = "UnitedKingdom";
      }
    ]
  );
}
# routes Rules TODO
# ++ [
#   {
#     domain_suffix = "wenziwanka.com";
#     outbound = "Default";
#   }
#   {
#     mode = "or";
#     outbound = "VoWiFi";
#     rules = [
#       {
#         network = "udp";
#         port = [
#           500
#           4500
#         ];
#       }
#       {
#         network = "tcp";
#         port = 143;
#       }
#       {
#         domain_suffix = [
#           "3gppnetwork.org"
#           "jibecloud.net"
#           "ee.co.uk"
#           "hkcsl.com"
#         ];
#       }
#     ];
#     type = "logical";
#   }
#   {
#     action = "reject";
#     domain_suffix = [
#       "2miners.com"
#       "donate.v2.xmrig"
#       "supportxmr.com"
#     ];
#   }
#   {
#     action = "reject";
#     process_name = [
#       "xmrig"
#       "xmrig.exe"
#     ];
#   }
#   {
#     domain_suffix = "marqeta.com";
#     outbound = "PayPal";
#     rule_set = "geosite-paypal";
#   }
#   {
#     domain_suffix = "checkfreeweb.com";
#     outbound = "HSBC";
#     rule_set = "geosite-hsbc";
#   }
#   {
#     outbound = "Kraken";
#     rule_set = "geosite-kraken";
#   }
#   {
#     domain_suffix = [
#       "okcoin.com"
#       "okx.ac"
#       "okx.cab"
#     ];
#     outbound = "OKX";
#     rule_set = "geosite-okx";
#   }
#   {
#     domain_regex = "trading212equities\\.s3\\.\\S+\\.amazonaws\\.com";
#     domain_suffix = "trading212.com";
#     outbound = "Trading212";
#   }
#   {
#     domain_suffix = [
#       "sumup.com"
#       "sumup.io"
#       "sumup.net"
#     ];
#     outbound = "SumUp";
#   }
#   {
#     domain_suffix = [
#       "curve.app"
#       "curve.com"
#       "curve.api.kustomerapp.com"
#       "imaginecurve.com"
#     ];
#     outbound = "CurvePay";
#   }
#   {
#     domain_suffix = [
#       "klarna.app"
#       "klarna.com"
#       "klarnacdn.net"
#       "klarnaevt.com"
#     ];
#     outbound = "Klarna";
#   }
#   {
#     domain = "gspe1-ssl.ls.apple.com";
#     outbound = "AI";
#     rule_set = [
#       "geosite-anthropic"
#       "geosite-apple-intelligence"
#       "geosite-bing"
#       "geosite-github"
#       "geosite-openai"
#       "geosite-perplexity"
#       "geosite-xai"
#       "geosite-google-gemini"
#     ];
#   }
#   {
#     domain_suffix = [
#       "wallet.coinbase.com"
#       "wallet.elephant-blue.org"
#       "t-mobile.com"
#       "connectbyt-mobile.com"
#     ];
#     outbound = "UnitedStates";
#     rule_set = [
#       "geosite-ibkr"
#       "asn-ibkr-as9096"
#       "asn-ibkr-as9468"
#       "asn-ibkr-as27163"
#       "asn-ibkr-as40711"
#     ];
#   }
#   {
#     domain_suffix = [
#       "bonify.de"
#       "coinbase.com"
#       "bybit.eu"
#       "braze.eu"
#     ];
#     outbound = "Germany";
#     rule_set = [
#       "geosite-bybit"
#       "geosite-n26"
#     ];
#   }
#   {
#     domain_suffix = "carousell.com.hk";
#     outbound = "HongKong";
#     rule_set = [
#       "geosite-hketgroup"
#       "geosite-line"
#     ];
#   }
#   {
#     domain = "moneyboxassets.blob.core.windows.net";
#     domain_suffix = [
#       "clearscore.com"
#       "creditkarma.co.uk"
#       "experian.co.uk"
#       "experianidentityservice.co.uk"
#       "expcdn.co.uk"
#       "equifax.co.uk"
#       "equifax.com"
#       "chase.co.uk"
#       "chase.intl"
#       "nutmeg.com"
#       "monzo.com"
#       "monzo-alt.net"
#       "nationwide.co.uk"
#       "tsb.co.uk"
#       "jaja.co.uk"
#       "yondercard.com"
#       "yonder.com"
#       "zable.co.uk"
#       "zopa.com"
#       "withplum.com"
#       "moneyboxapp.com"
#       "chiphq.net"
#       "backpack.exchange"
#       "backpack.workers.dev"
#       "neverless.com"
#       "freetrade.io"
#       "freetrade.app"
#       "remitly.com"
#       "remitly.io"
#       "remitly-3pjs.com"
#       "remit.ly"
#       "skrill.com"
#       "lemfi.com"
#       "lemonade.finance"
#       "lemonadefi.app.link"
#       "taptapsend.com"
#       "westernunion.com"
#       "truelayer.com"
#       "yapily.com"
#       "zimperium.com"
#     ];
#     outbound = "UnitedKingdom";
#     rule_set = [
#       "geosite-wise"
#       "geosite-stripe"
#     ];
#   }
#   {
#     outbound = "Apple";
#     rule_set = [
#       "geoip-apple"
#       "geosite-apple"
#     ];
#   }
#   {
#     outbound = "Direct";
#     rule_set = "geosite-category-game-platforms-download";
#   }
#   {
#     outbound = "Games";
#     rule_set = "geosite-category-games";
#   }
#   {
#     outbound = "Google";
#     rule_set = [
#       "geoip-google"
#       "geosite-google"
#       "geosite-youtube"
#     ];
#   }
#   {
#     outbound = "Meta";
#     rule_set = [
#       "geoip-facebook"
#       "geosite-meta"
#     ];
#   }
#   {
#     outbound = "Microsoft";
#     rule_set = "geosite-microsoft";
#   }
#   {
#     outbound = "Oracle";
#     rule_set = "geosite-oracle";
#   }
#   {
#     outbound = "Pixiv";
#     rule_set = "geosite-pixiv";
#   }
#   {
#     outbound = "Category-Speedtest";
#     rule_set = "geosite-category-speedtest";
#   }
# ];

# TODO DNS rules
# ++ [
#   {
#     domain_suffix = [
#       "klarna.app"
#       "klarna.com"
#       "klarnacdn.net"
#       "klarnaevt.com"
#     ];
#     server = "klarna";
#   }
#   {
#     domain = "gspe1-ssl.ls.apple.com";
#     rule_set = [
#       "geosite-anthropic"
#       "geosite-apple-intelligence"
#       "geosite-bing"
#       "geosite-github"
#       "geosite-openai"
#       "geosite-perplexity"
#       "geosite-xai"
#       "geosite-google-gemini"
#     ];
#     server = "ai";
#   }
#   {
#     domain_suffix = [
#       "wallet.coinbase.com"
#       "wallet.elephant-blue.org"
#       "t-mobile.com"
#       "connectbyt-mobile.com"
#     ];
#     rule_set = "geosite-ibkr";
#     server = "us";
#   }
#   {
#     domain_suffix = [
#       "bonify.de"
#       "coinbase.com"
#       "bybit.eu"
#       "braze.eu"
#     ];
#     rule_set = [
#       "geosite-bybit"
#       "geosite-n26"
#     ];
#     server = "de";
#   }
#   {
#     domain_suffix = "carousell.com.hk";
#     rule_set = [
#       "geosite-hketgroup"
#       "geosite-line"
#     ];
#     server = "hk";
#   }
#   {
#     domain = "moneyboxassets.blob.core.windows.net";
#     domain_suffix = [
#       "clearscore.com"
#       "creditkarma.co.uk"
#       "experian.co.uk"
#       "experianidentityservice.co.uk"
#       "expcdn.co.uk"
#       "equifax.co.uk"
#       "equifax.com"
#       "chase.co.uk"
#       "chase.intl"
#       "nutmeg.com"
#       "monzo.com"
#       "monzo-alt.net"
#       "nationwide.co.uk"
#       "tsb.co.uk"
#       "jaja.co.uk"
#       "yondercard.com"
#       "yonder.com"
#       "zable.co.uk"
#       "zopa.com"
#       "withplum.com"
#       "moneyboxapp.com"
#       "chiphq.net"
#       "backpack.exchange"
#       "backpack.workers.dev"
#       "neverless.com"
#       "freetrade.io"
#       "freetrade.app"
#       "remitly.com"
#       "remitly.io"
#       "remitly-3pjs.com"
#       "remit.ly"
#       "skrill.com"
#       "lemfi.com"
#       "lemonade.finance"
#       "lemonadefi.app.link"
#       "taptapsend.com"
#       "westernunion.com"
#       "truelayer.com"
#       "yapily.com"
#       "zimperium.com"
#     ];
#     rule_set = [
#       "geosite-wise"
#       "geosite-stripe"
#     ];
#     server = "gb";
#   }
#   {
#     rule_set = "geosite-apple";
#     server = "apple";
#   }
#   {
#     rule_set = "geosite-category-game-platforms-download";
#     server = "china";
#   }
#   {
#     rule_set = "geosite-category-games";
#     server = "games";
#   }
#   {
#     rule_set = [
#       "geosite-google"
#       "geosite-youtube"
#     ];
#     server = "google";
#   }
#   {
#     rule_set = "geosite-meta";
#     server = "meta";
#   }
#   {
#     rule_set = "geosite-microsoft";
#     server = "microsoft";
#   }
#   {
#     rule_set = "geosite-oracle";
#     server = "oracle";
#   }
#   {
#     rule_set = "geosite-pixiv";
#     server = "pixiv";
#   }
#   {
#     rule_set = "geosite-category-speedtest";
#     server = "category-speedtest";
#   }
# ];
#
# TODO outbounds              {
#   tag = "Klarna";
#   type = "selector";
#   default = "UnitedKingdom";
#   inherit outbounds;
# }
# {
#   tag = "AI";
#   type = "selector";
#   default = "UnitedStates";
#   inherit outbounds;
# }
# {
#   tag = "Apple";
#   type = "selector";
#   default = "Direct";
#   inherit outbounds;
# }
# {
#   tag = "Meta";
#   type = "selector";
#   default = "UnitedKingdom";
#   inherit outbounds;
# }
# {
#   tag = "Games";
#   type = "selector";
#   default = "Default";
#   inherit outbounds;
# }
# {
#   tag = "Google";
#   type = "selector";
#   default = "Default";
#   inherit outbounds;
# }
# {
#   tag = "Microsoft";
#   type = "selector";
#   default = "Direct";
#   inherit outbounds;
# }
# {
#   tag = "Oracle";
#   type = "selector";
#   default = "UnitedKingdom";
#   inherit outbounds;
# }
# {
#   tag = "BiliBili";
#   type = "selector";
#   default = "Direct";
#   inherit outbounds;
# }
# {
#   tag = "Pixiv";
#   type = "selector";
#   default = "HongKong";
#   inherit outbounds;
# }
# {
#   tag = "Category-Speedtest";
#   type = "selector";
#   default = "Default";
#   inherit outbounds;
# }
