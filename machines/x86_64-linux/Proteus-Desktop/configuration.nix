{
  config,
  lib,
  myvars,
  ...
}: let
  ifaces = myvars.networking.hosts_addr.${config.networking.hostName};
  iface_wire = builtins.elemAt ifaces 2;
  iface_wlan = builtins.elemAt ifaces 3;
in {
  boot.binfmt.emulatedSystems = ["riscv64-linux"]; # Cross compilation
  ## BEGIN sing-box.nix
  sops.secrets."sb_client_linux.json" = {
    sopsFile = "${myvars.secrets_dir}/sb_client_linux.json.sops";
    format = "binary";
    restartUnits = ["sing-box.service"];
  };
  services.sing-box.enable = true;
  services.sing-box.configFile = config.sops.secrets."sb_client_linux.json".path;
  ## END sing-box.nix
  ## BEGIN systemd_tmpfiles.nix
  # systemd.tmpfiles.settings = {
  #   # Setgid so new files inherit group; give rw to group members
  #   "00-create-data-share"."${myvars.storage_path}/share".d = {group = "storage"; mode = "2775";};
  #   # Even with setgid, services may create files with restrictive umasks. Lock in permissions with default ACLs
  #   # TIP: You may change type to `A+` to recursively modify exists dirs/files' ACLs
  #   # TIP: Run `getfacl /path` to show rule list
  #   "01-acl-data-share-default"."${myvars.storage_path}/share"."a+".argument = "d:g:storage:rwX";
  #   "01-acl-data-share"."${myvars.storage_path}/share".a.argument = "g:storage:rwX";
  # };
  ## END systemd_tmpfiles.nix
  ## BEGIN hostapd.nix
  boot.extraModulePackages = [config.boot.kernelPackages.rtl8812au];
  boot.kernelModules = ["8812au"];
  sops.secrets."proteus_ap_password" = {
    sopsFile = "${myvars.secrets_dir}/Proteus-Desktop.sops.yaml";
    restartUnits = ["hostapd.service"];
  };
  services.hostapd = {
    enable = true;
    radios.${iface_wlan.name} = {
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
        ${iface_wlan.name} = {
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
            wpaPasswordFile = config.sops.secrets."proteus_ap_password".path;
            # mode = "wpa3-sae"; saePasswords = [{passwordFile = config.sops.secrets."proteus_ap_password.key".path;}];
          };
        };
      };
    };
  };
  networking.interfaces.${iface_wlan.name}.ipv4.addresses = [
    {
      address = iface_wlan.priv_ipv4;
      prefixLength = iface_wlan.ipv4_prefix_len;
    }
  ];
  networking.nftables.tables = lib.mkIf config.services.sing-box.enable {
    hostapd_bypass = {
      family = "inet";
      content = with (builtins.head config.networking.interfaces.${iface_wlan.name}.ipv4.addresses); ''
        chain prerouting {
          type filter hook prerouting priority dstnat - 5; policy accept;

          # 1. Do NOT bypass FakeIP traffic. Let sing-box handle it.
          ip daddr 198.18.0.0/15 return

          # 2. Bypass everything else from hostapd managed iface
          # ip saddr ${address}/${toString prefixLength} ct mark set 0x00002024
        }
      '';
    };
  };
  networking.firewall.extraInputRules = with (
    builtins.head config.networking.interfaces.${iface_wlan.name}.ipv4.addresses
  ); ''
    ip saddr ${address}/${toString prefixLength} accept comment "Allow hostapd clients to reach auto_redirect ports"
  '';
  services.dnsmasq = {
    enable = true;
    settings = {
      # We can keep systemd-resolved listening on 127.0.0.53:53 and keep dnsmasq solely on the wlan interface by telling
      # it to only bind there, this prevents conflicts with systemd-resolved
      interface = iface_wlan.name;
      bind-interfaces = true;
      dhcp-range = ["192.168.12.10,192.168.12.240,12h"];
      # Tell DHCP clients to use 223.5.5.5 as their DNS server so sing-box can hijack
      dhcp-option = ["option:dns-server,223.5.5.5"];
    };
  };
  networking.nat = {
    enable = true;
    # The interface connected to the internet (e.g., eth0, wlan0 onboard)
    externalInterface = iface_wire.name;
    internalInterfaces = [iface_wlan.name]; # The interface acting as the hotspot
  };
  ## END hostapd.nix
}
