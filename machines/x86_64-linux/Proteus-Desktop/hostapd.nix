{
  config,
  lib,
  const,
  ...
}:
let
  hostname = config.networking.hostName;
  nics = config.vars.hostAddrs.${hostname};
in
{
  vars.hostAddrs.${hostname}.wireless = {
    name = "wlp0s20u9";
    ipv4 = "192.168.12.1/24";
  };

  boot.extraModulePackages = [ config.boot.kernelPackages.rtl8812au ];
  boot.kernelModules = [ "8812au" ];
  boot.requiredKernelModules = [ "rtl8812au" ];

  sops.secrets.proteus_ap_password = {
    sopsFile = "${const.secretsDir}/Proteus-Desktop.sops.yaml";
    restartUnits = [ "hostapd.service" ];
  };
  services.hostapd = {
    enable = true;
    radios.${nics.wireless.name} = {
      band = "2g"; # "5g" is `hw_mode=a`, "2g" is `hw_mode=g`
      # Primary control channel, `0` use ACS (not all devices supported)
      channel = 6;
      countryCode = "US";
      # Band 1 Capabilities
      # NOTE on Band 2 some wifi4 capibilities is unavailable
      wifi4.capabilities = [
        "HT40+"
        "SMPS-STATIC"
        "SHORT-GI-20"
        "SHORT-GI-40"
        "RX-STBC1"
        "MAX-AMSDU-7935"
        "DSSS_CCK-40"
      ];
      # wifi5.operatingChannelWidth = "80";
      # These are in Band 2 Capabilities
      # wifi5.capabilities = ["MAX-MPDU-11454" "SHORT-GI-80" "TX-STBC-2BY1" "SU-BEAMFORMEE" "HTC-VHT"];
      networks = {
        ${nics.wireless.name} = {
          ssid = "Proteus_AP";
          settings = {
            # vht_oper_centr_freq_seg0_idx = "155"; # Center frequency index (only for 80MHz or wider)
            # Disable Protected Management Frames (802.11w), WPA3 (SAE) requires this to be enabled
            # ieee80211w = 0;
            ieee80211d = true; # Advertises the country_code
            ieee80211h = true; # Dynamic Frequency Selection
          };
          authentication = {
            # "wpa2-sha1" is standard WPA2-PSK (AES/CCMP). "wpa2-sha256" causes issues.
            mode = "wpa2-sha1";
            wpaPasswordFile = config.sops.secrets.proteus_ap_password.path;
            # mode = "wpa3-sae"; saePasswords = [{passwordFile = config.sops.secrets."proteus_ap_password.key".path;}];
          };
        };
      };
    };
  };
  networking.interfaces.${nics.wireless.name}.ipv4.addresses = [
    {
      address = nics.wireless.ipv4NoCidr;
      prefixLength = lib.toInt (lib.last (lib.splitString "/" nics.wireless.ipv4));
    }
  ];
  networking.firewall.extraInputRules = ''
    ip saddr ${
      config.vars.hostAddrs.${hostname}.wireless.ipv4
    } accept comment "Allow hostapd clients to reach auto_redirect ports"
  '';
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false; # Don't run on `127.0.0.1`
    # Ref: https://man.archlinux.org/man/dnsmasq.8.en
    settings = {
      # We can keep systemd-resolved listening on 127.0.0.53:53 and keep dnsmasq solely on the wlan interface by telling
      # it to only bind there, this prevents conflicts with systemd-resolved
      interface = nics.wireless.name; # Only listen on the specified NIC
      # dnsmasq binds the wildcard address even when it is listening on only some interfaces. This option forces dnsmasq
      # to really bind only the interfaces it is listening on.
      bind-interfaces = true;
      except-interface = "lo"; # Dnsmasq automatically adds the loopback NIC when the --interface option is use

      dhcp-range =
        let
          prefix = builtins.concatStringsSep "." (
            lib.take 3 (lib.splitString "." config.vars.hostAddrs.Proteus-Desktop.wireless.ipv4)
          );
        in
        [ "${prefix}.10,${prefix}.240,12h" ];
      # Tell DHCP clients to use 223.5.5.5 as their DNS server so sing-box can hijack
      dhcp-option = [ "option:dns-server,223.5.5.5" ];
    };
  };
  networking.nat = {
    enable = true;
    # The interface connected to the internet (e.g., eth0, wlan0 onboard)
    externalInterface = nics.wire.name;
    internalInterfaces = [ nics.wireless.name ]; # The interface acting as the hotspot
  };
}
