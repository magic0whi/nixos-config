{
  inputs,
  pkgs,
}:
let
  inherit (pkgs) lib;
  mylib = import ./default.nix { inherit inputs; };
  mylib_pkgs = mylib.mk_for_pkgs pkgs;
in
lib.runTests {
  ## BEGIN System Agnostic Tests
  test_relative_to_root = {
    expr = mylib.relative_to_root "test_dir";
    expected = ../. + "/test_dir";
  };

  # Bare host and port
  test_get_uri_port_bare = {
    expr = mylib.get_uri_port "127.0.0.1:3903";
    expected = 3903;
  };
  # Bare host and port with path
  test_get_uri_port_bare_path = {
    expr = mylib.get_uri_port "127.0.0.1:3903/path";
    expected = 3903;
  };

  # HTTP default port
  test_get_uri_port_http_default = {
    expr = mylib.get_uri_port "http://example.com";
    expected = 80;
  };
  # HTTPS default port
  test_get_uri_port_https_default = {
    expr = mylib.get_uri_port "https://example.com";
    expected = 443;
  };
  # HTTPS port overrides
  test_get_uri_port_https_port_overrides = {
    expr = mylib.get_uri_port "https://example.com:8443";
    expected = 8443;
  };

  # Unknown scheme with no port
  test_get_uri_port_unknown_scheme = {
    expr = mylib.get_uri_port "unknown://example.com";
    expected = null;
  };
  # Unknown scheme with port
  test_get_uri_port_unknown_scheme_port_233 = {
    expr = mylib.get_uri_port "unknown://example.com:233";
    expected = 233;
  };

  # URI with path
  test_get_uri_port_port_233_path = {
    expr = mylib.get_uri_port "unknown://example.com:233/foo/bar/";
    expected = 233;
  };
  # URI with query string and no path
  test_get_uri_port_query_no_path = {
    expr = mylib.get_uri_port "unknown://example.com:8081?foo=bar";
    expected = 8081;
  };
  # URI with fragment and no path
  test_get_uri_port_fragment_no_path = {
    expr = mylib.get_uri_port "unknown://example.com:8081#section";
    expected = 8081;
  };
  # Proxied URI (port in authority, full URI in path)
  test_get_uri_port_proxy_uri_in_path = {
    expr = mylib.get_uri_port "https://proxy.example.com:8081/https://github.com";
    expected = 8081;
  };
  # IPv6 address with port
  test_get_uri_port_ipv6 = {
    expr = mylib.get_uri_port "unknown://[::1]:9090/path";
    expected = 9090;
  };
  # IPv6 address, port 443
  test_get_uri_port_ipv6_port_443 = {
    expr = mylib.get_uri_port "https://[fd7a:115c:a1e0::cd3a:a114]:443";
    expected = 443;
  };
  ## END System Agnostic Tests
  ## BEGIN System Dependent Tests
  # Verifies that mk_out_of_store_symlink correctly strips unsafe characters
  # from the generated derivation name.
  test_mk_out_of_store_symlink_symlink_name_sanitization = {
    expr = (mylib_pkgs.mk_out_of_store_symlink "/home/user/my unsafe path!@#.txt").name;
    expected = "custom_myunsafepath.txt";
  };
  ## END System Dependent Tests
}
