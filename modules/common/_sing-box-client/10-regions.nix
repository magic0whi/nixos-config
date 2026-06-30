{ dnsServerCfg, lib, ... }:
let
  outbounds = [
    {
      tag = "HongKong";
      type = "selector";
      outbounds = [
        "Proteus-NixOS-5"
        "{all}"
      ];
      filter = [
        {
          action = "include";
          keywords = [ "🇭🇰|HK|hk|香港|港|HongKong" ];
        }
      ];
    }
    {
      tag = "UnitedKingdom";
      type = "selector";
      outbounds = [
        "Proteus-NixOS-4"
        "Proteus-NixOS-3"
        "{all}"
      ];
      filter = [
        {
          action = "include";
          keywords = [ "🇬🇧|UK|uk|英国|英|United Kingdom" ];
        }
      ];
    }
    {
      tag = "UnitedStates";
      type = "selector";
      outbounds = [
        # "Proteus-NixOS-0"
        "{all}"
      ];
      filter = [
        {
          action = "include";
          keywords = [ "🇺🇸|US|us|美国|美|United States" ];
        }
      ];
    }
    {
      tag = "Taiwan";
      type = "selector";
      outbounds = [ "{all}" ];
      filter = [
        {
          action = "include";
          keywords = [ "🇹🇼|TW|tw|台湾|臺灣|台|Taiwan" ];
        }
      ];
    }
    {
      tag = "Singapore";
      type = "selector";
      outbounds = [ "{all}" ];
      filter = [
        {
          action = "include";
          keywords = [ "🇸🇬|SG|sg|新加坡|狮|Singapore" ];
        }
      ];
    }
    {
      tag = "Japan";
      type = "selector";
      outbounds = [ "{all}" ];
      filter = [
        {
          action = "include";
          keywords = [ "🇯🇵|JP|jp|日本|Japan" ];
        }
      ];
    }
    {
      tag = "Germany";
      type = "selector";
      outbounds = [
        "Proteus-NixOS-2"
        "{all}"
      ];
      filter = [
        {
          action = "include";
          keywords = [ "🇩🇪|GE|ge|DE|de|德国|德|Germany|Deutschland" ];
        }
      ];
    }
    {
      tag = "Others";
      type = "selector";
      outbounds = [
        # "Socks5"
        "{all}"
      ];
      filter = [
        {
          action = "exclude";
          keywords = [
            "🇭🇰|HK|hk|香港|港|HongKong|🇹🇼|TW|tw|台湾|臺灣|台|Taiwan|🇸🇬|SG|sg|新加坡|狮|Singapore|🇯🇵|JP|jp|日本|Japan|🇺🇸|US|us|美国|美|United States|🇬🇧|UK|uk|英国|英|United Kingdom|🇩🇪|GE|ge|DE|de|德国|德|Germany|Deutschland"
          ];
        }
      ];
    }
  ];
in
{
  dns.servers = lib.mkBefore (
    map (
      tag:
      dnsServerCfg.default
      // {
        inherit tag;
        detour = tag;
      }
    ) (map (outbound: outbound.tag) outbounds)
  );
  inherit outbounds;
}
