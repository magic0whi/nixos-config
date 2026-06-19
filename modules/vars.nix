# Custom op#otions as global variables
{ lib, ... }:
{
  options.vars.hostAddrs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Predictable NIC name";
              };

              ipv4 = lib.mkOption {
                type = lib.types.str;
                description = "The IPv4 address of this NIC";
              };
              ipv4NoCidr = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = builtins.head (lib.strings.splitString "/" config.ipv4);
              };

              ipv6 = lib.mkOption {
                type = lib.types.str;
                description = "The IPv6 address of this NIC";
              };
              ipv6NoCidr = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
                default = builtins.head (lib.strings.splitString "/" config.ipv6);
              };

              domains = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    A = lib.mkOption {
                      type = with lib.types; listOf str;
                      default = [ ];
                      description = "List of subdomains that should resolve to this interface's IPv4 address.";
                    };
                    AAAA = lib.mkOption {
                      type = with lib.types; listOf str;
                      default = [ ];
                      description = "List of subdomains that should resolve to this interface's IPv6 address.";
                    };
                    # CNAME = lib.mkOption {
                    #   type = with lib.types; listOf str;
                    #   default = [ ];
                    #   description = ''
                    #     List of subdomains that should be aliased to this host's hostname via CNAME records.
                    #   '';
                    # };
                  };
                };
                default = { };
                description = ''
                  Additional subdomain records (A, AAAA, CNAME) attached to this network interface.
                '';
              };
            };
          }
        )
      )
    );
  };
}
