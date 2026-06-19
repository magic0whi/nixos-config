{ const, ... }:
{
  services.jellyfin =
    let
      use_nvidia = true;
    in
    {
      enable = true;
      hardwareAcceleration = {
        enable = true;
        device = if use_nvidia then "/dev/dri/${const.dgpu_sym_name}" else "/dev/dri/${const.igpu_sym_name}";
        type = "vaapi";
      };
      transcoding = {
        enableHardwareEncoding = true;
        enableIntelLowPowerEncoding = if use_nvidia then false else true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          hevc10bit = true;
          hevcRExt10bit = true;
          hevcRExt12bit = true;
          mpeg2 = true;
          vc1 = true;
          vp8 = true;
          vp9 = true;
        };
        hardwareEncodingCodecs.hevc = true;
      };
    };
  services.traefik.dynamicConfigOptions.http = {
    middlewares.jellyfin-headers.headers = {
      # The customResponseHeaders option lists the Header names and values to apply to the response.
      customResponseHeaders = {
        X-Robots-Tag = "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
        # Set browserXssFilter to true to add the X-XSS-Protection header with the value 1; mode=block.
        X-XSS-PROTECTION = 1;
      };
      # The stsSeconds is the max-age of the Strict-Transport-Security header. If set to 0, would NOT include the
      # header.
      stsSeconds = 315360000;
      # The stsIncludeSubdomains is set to true, the includeSubDomains directive will be appended to the
      # Strict-Transport-Security header.
      stsIncludeSubdomains = true;
      # Set stsPreload to true to have the preload flag appended to the Strict-Transport-Security header.
      stsPreload = true;
      # Set forceSTSHeader to true, to add the STS header even when the connection is HTTP.
      forceSTSHeader = true;
      # Set contentTypeNosniff to true to add the X-Content-Type-Options header with the value nosniff.
      contentTypeNosniff = true;
    };
    routers.jellyfin = {
      rule = "Host(`jellyfin.${const.domain}`)";
      entryPoints = [ "websecure" ];
      middlewares = [ "jellyfin-headers" ];
      service = "jellyfin";
      tls = { };
    };
    services.jellyfin.loadBalancer.servers = [ { url = "http://127.0.0.1:8096"; } ];
  };
}
