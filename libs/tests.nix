{
  inputs,
  pkgs,
}:
let
  inherit (pkgs) lib;
  mylib = import ./default.nix { inherit inputs; };
  mylib_pkgs = mylib.mkForPkgs pkgs;
in
lib.runTests {
  ## BEGIN System Agnostic Tests
  test_relativeToRoot = {
    expr = mylib.relativeToRoot "test_dir";
    expected = ../. + "/test_dir";
  };

  # Bare host and port
  test_getUriPort_bare = {
    expr = mylib.getUriPort "127.0.0.1:3903";
    expected = 3903;
  };
  # Bare host and port with path
  test_getUriPort_bare_path = {
    expr = mylib.getUriPort "127.0.0.1:3903/path";
    expected = 3903;
  };

  # HTTP default port
  test_getUriPort_http_default = {
    expr = mylib.getUriPort "http://example.com";
    expected = 80;
  };
  # HTTPS default port
  test_getUriPort_https_default = {
    expr = mylib.getUriPort "https://example.com";
    expected = 443;
  };
  # HTTPS port overrides
  test_getUriPort_https_port_overrides = {
    expr = mylib.getUriPort "https://example.com:8443";
    expected = 8443;
  };

  # Unknown scheme with no port
  test_getUriPort_unknown_scheme = {
    expr = mylib.getUriPort "unknown://example.com";
    expected = null;
  };
  # Unknown scheme with port
  test_getUriPort_unknown_scheme_port_233 = {
    expr = mylib.getUriPort "unknown://example.com:233";
    expected = 233;
  };

  # URI with path
  test_getUriPort_port_233_path = {
    expr = mylib.getUriPort "unknown://example.com:233/foo/bar/";
    expected = 233;
  };
  # URI with query string and no path
  test_getUriPort_query_no_path = {
    expr = mylib.getUriPort "unknown://example.com:8081?foo=bar";
    expected = 8081;
  };
  # URI with fragment and no path
  test_getUriPort_fragment_no_path = {
    expr = mylib.getUriPort "unknown://example.com:8081#section";
    expected = 8081;
  };
  # Proxied URI (port in authority, full URI in path)
  test_getUriPort_proxy_uri_in_path = {
    expr = mylib.getUriPort "https://proxy.example.com:8081/https://github.com";
    expected = 8081;
  };
  # IPv6 address with port
  test_getUriPort_ipv6 = {
    expr = mylib.getUriPort "unknown://[::1]:9090/path";
    expected = 9090;
  };
  # IPv6 address, port 443
  test_getUriPort_ipv6_port_443 = {
    expr = mylib.getUriPort "https://[fd7a:115c:a1e0::cd3a:a114]:443";
    expected = 443;
  };
  ## END System Agnostic Tests
  ## BEGIN System Dependent Tests
  # Verifies that mkOutOfStoreSymlink correctly strips unsafe characters
  # from the generated derivation name.
  test_mkOutOfStoreSymlink_symlink_name_sanitization = {
    expr = (mylib_pkgs.mkOutOfStoreSymlink "/home/user/my unsafe path!@#.txt").name;
    expected = "custom_myunsafepath.txt";
  };
  ## END System Dependent Tests
}
