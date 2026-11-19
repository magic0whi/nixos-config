{ lib, ... }:
{
  options.vars.forwardAuthServices = lib.mkOption {
    type = with lib.types; listOf str;
    example = [
      "prometheus"
      "exporter"
    ];
    description = ''
      Keywords of services protected by the Authelia forward-auth middleware (`authelia-auth`). Hosts having subdomains
      containing these keywords will be allowed forwardedHeaders in Traefik, so the X-Forwarded-* headers their Traefik
      sends to Authelia are preserved. OIDC-only services do not need this.
    '';
  };
}
