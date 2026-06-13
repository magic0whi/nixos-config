{ sharedRuleSetCfg, ... }:
{
  route.rule_set =
    let
      inherit (sharedRuleSetCfg) urlPrefix defaultCfg;
    in
    map (rule_set: defaultCfg // rule_set) [
      # AI
      {
        tag = "geosite-github";
        url = "${urlPrefix}/geo/geosite/github.srs";
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
        tag = "geosite-openai";
        url = "${urlPrefix}/geo/geosite/openai.srs";
      }
      {
        tag = "geosite-anthropic";
        url = "${urlPrefix}/geo/geosite/anthropic.srs";
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

      {
        tag = "geoip-apple";
        url = "${urlPrefix}/geo-lite/geoip/apple.srs";
      }
      {
        tag = "geosite-apple";
        url = "${urlPrefix}/geo/geosite/apple.srs";
      }

      {
        tag = "geoip-google";
        url = "${urlPrefix}/geo/geoip/google.srs";
      }
      {
        tag = "geosite-google";
        url = "${urlPrefix}/geo/geosite/google.srs";
      }
      {
        tag = "geosite-youtube";
        url = "${urlPrefix}/geo/geosite/youtube.srs";
      }

      {
        tag = "geoip-facebook";
        url = "${urlPrefix}/geo/geoip/facebook.srs";
      }
      {
        tag = "geosite-meta";
        url = "${urlPrefix}/geo/geosite/meta.srs";
      }

      {
        tag = "geosite-microsoft";
        url = "${urlPrefix}/geo/geosite/microsoft.srs";
      }

      {
        tag = "geosite-category-games";
        url = "${urlPrefix}/geo/geosite/category-games.srs";
      }
      {
        tag = "geosite-category-game-platforms-download";
        url = "${urlPrefix}/geo/geosite/category-game-platforms-download.srs";
      }

      # Cryptocurrency
      {
        tag = "geosite-bybit";
        url = "${urlPrefix}/geo/geosite/bybit.srs";
      }
      {
        tag = "geosite-okx";
        url = "${urlPrefix}/geo/geosite/okx.srs";
      }
      {
        tag = "geosite-kraken";
        url = "${urlPrefix}/geo/geosite/kraken.srs";
      }

      {
        tag = "geosite-paypal";
        url = "${urlPrefix}/geo/geosite/paypal.srs";
      }

      {
        tag = "geosite-n26";
        url = "${urlPrefix}/geo/geosite/n26.srs";
      }

      {
        tag = "geosite-wise";
        url = "${urlPrefix}/geo/geosite/wise.srs";
      }

      {
        tag = "geosite-stripe";
        url = "${urlPrefix}/geo/geosite/stripe.srs";
      }

      # Banks (CN)
      {
        tag = "geosite-boc";
        url = "${urlPrefix}/geo/geosite/boc.srs";
      }
      {
        tag = "geosite-ccb";
        url = "${urlPrefix}/geo/geosite/ccb.srs";
      }
      {
        tag = "geosite-hsbc";
        url = "${urlPrefix}/geo/geosite/hsbc.srs";
      }
      {
        tag = "geosite-icbc";
        url = "${urlPrefix}/geo/geosite/icbc.srs";
      }

      {
        tag = "geosite-ifast";
        url = "${urlPrefix}/geo/geosite/ifast.srs";
      }

      {
        tag = "geosite-alibaba@!cn";
        url = "${urlPrefix}/geo/geosite/alibaba@!cn.srs";
      }

      {
        tag = "geosite-line";
        url = "${urlPrefix}/geo/geosite/line.srs";
      }

      {
        tag = "geosite-hketgroup";
        url = "${urlPrefix}/geo/geosite/hketgroup.srs";
      }

      {
        tag = "geosite-oracle";
        url = "${urlPrefix}/geo/geosite/oracle.srs";
      }

      {
        tag = "geosite-ibkr";
        url = "${urlPrefix}/geo/geosite/ibkr.srs";
      }
      {
        tag = "asn-ibkr-as9096";
        url = "${urlPrefix}/asn/AS9096.srs";
      }
      {
        tag = "asn-ibkr-as9468";
        url = "${urlPrefix}/asn/AS9468.srs";
      }
      {
        tag = "asn-ibkr-as27163";
        url = "${urlPrefix}/asn/AS27163.srs";
      }
      {
        tag = "asn-ibkr-as40711";
        url = "${urlPrefix}/asn/AS40711.srs";
      }

      {
        tag = "geosite-schwab";
        url = "${urlPrefix}/geo/geosite/schwab.srs";
      }

      {
        tag = "geosite-pixiv";
        url = "${urlPrefix}/geo/geosite/pixiv.srs";
      }

      {
        tag = "geosite-tencent";
        url = "${urlPrefix}/geo/geosite/tencent.srs";
      }

      {
        tag = "geosite-category-speedtest";
        url = "${urlPrefix}/geo/geosite/category-speedtest.srs";
      }

      # Catch-all
      {
        tag = "geoip-cn";
        url = "${urlPrefix}/geo/geoip/cn.srs";
      }
      {
        tag = "geosite-cn";
        url = "${urlPrefix}/geo/geosite/cn.srs";
      }
    ];
}
