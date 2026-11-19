{ config, lib, ... }: {
  networking.firewall = {
    trustedInterfaces = lib.singleton (
      (lib.findFirst (inbound: inbound.type == "tun") { } (config.services.sing-box.settings.inbounds or [ ])).interface_name
        or "sing0"
    );
    # sing-box's auto_redirect installs a nat prerouting rule that redirects intercepted packets to a local
    # listener port. Redirect is DNAT to this host's own address, so the routing decision that follows sends the
    # packet to the input hook instead of forward -- where networking.firewall's `policy drop` kills it silently
    # (no RST, so clients hang until they time out).
    #
    # Matching on `ct status dnat` accepts exactly those packets: conntrack sets the dnat flag only for connections
    # one of sing-box's nat chains rewrote, so nothing off-box can forge it.
    #
    # NOTE: do not narrow this to `tcp dport 42403`. sing-box randomly chooses the auto_redirect listener port at
    # startup; hardcoding it breaks on restart, and breaks quietly, because DNS keeps working while others dies.
    extraInputRules = ''ct status dnat accept comment "Accept traffic redirected by sing-box auto_redirect"'';
  };
}
