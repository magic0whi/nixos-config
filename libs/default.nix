lib:
let
  dns_rule_filter = rule: !(rule ? ip_cidr || rule ? network || rule ? port);
in
{
  ## BEGIN pkgs agnostic functions
  # Don't put ip related rules along with other things as it will filter the whole rule
  # NOTE in 1.14, there is a new feature evaluate, which allows query DNS result and use the result  to do IP matches
  # later
  mkSbRules =
    forDns: out: rules:
    (map (rule: (if forDns then { server = out; } else { outbound = out; }) // rule) (
      if forDns then lib.filter dns_rule_filter rules else rules
    ));
  mkSbRules' =
    forDns: defCfg: rules:
    (map (rule: defCfg // rule) (if forDns then lib.filter dns_rule_filter rules else rules));

  # Use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;

  scanPath =
    path:
    map (fn: path + "/${fn}") (
      builtins.attrNames (
        lib.filterAttrs
          # Exclude if `_` prefix, include directories and *.nix, exclude default.nix
          (e: t: !(lib.hasPrefix "_" e) && ((t == "directory") || ((lib.hasSuffix ".nix" e) && (e != "default.nix"))))
          (builtins.readDir path)
      )
    );
  getUriPort =
    uri:
    let
      # 1. Strip scheme ("https://", "http://", etc.)
      # Use `lib.drop` instead of `builtins.head` for edge cases like "https://proxy.example.com:8081/https://github.com"
      strip_scheme =
        let
          _stripe_scheme = lib.drop 1 (lib.splitString "://" uri);
        in
        # Handle edge case for bare host and port, e.g. "127.0.0.1:3903"
        if builtins.length _stripe_scheme > 0 then builtins.head _stripe_scheme else uri;
      # 2. Take only the authority+path portion before any "?" or "#".
      # For edge cases like ("https://example.com:8081?foo=bar", "https://example.com:8081?foo=bar")
      authority_path = builtins.head (lib.splitString "?" (builtins.head (lib.splitString "#" strip_scheme)));
      # 3. Take only the authority (before the first "/")
      authority = builtins.head (lib.splitString "/" authority_path);
      # 4. Strip IPv6 bracket notation before splitting on ":". e.g. "[::1]:8080" -> ["[::1" ":8080"] -> ":8080"
      authority_no_bracket = lib.last (lib.splitString "]" authority);
      # 5. Strip domain.
      port =
        let
          _port = lib.drop 1 (lib.splitString ":" authority_no_bracket);
        in
        if builtins.length _port > 0 then builtins.head _port else null; # Handle edge cases like "example.com" -> []
      # port = lib.last (lib.splitString ":" authority_no_bracket);
      # 6. Fallback process
      scheme = builtins.head (lib.splitString "://" uri);
      # in if builtins.match "[0-9]+" port != null then lib.toInt port
    in
    if port != null then
      lib.toInt port
    else if scheme == "https" then
      443
    else if scheme == "http" then
      80
    else if scheme == "ftp" then
      21
    else if scheme == "ssh" then
      22
    else
      null;

  genDeployNode_unwrapped = deployLib: nics: nixosCfg: {
    hostname =
      # TODO temporary disable EasyTier
      # nics.easytier.ipv4NoCidr or
      nics.tailscale.ipv4NoCidr or nixosCfg.config.networking.hostName;
    sshUser = "root";
    interactiveSudo = false; # I use the root user to ssh deploy
    profiles.system = {
      path = deployLib.${nixosCfg.pkgs.stdenv.hostPlatform.system}.activate.nixos nixosCfg;
      user = "root";
    };
  };

  mkCaddyVHost = rootPath: {
    listenAddresses = [
      "127.0.0.1"
      "[::1]"
    ];
    extraConfig = ''
      # respond "Hello, world!" # For debug
      root * ${rootPath}

      # file_server directive is required if serve static files from disk
      file_server
      # If you want directory listings
      # file_server browse

      # Enable compress, default zstd
      encode
    '';
  };

  toEnv = lib.generators.toKeyValue { };
  toYAML = lib.generators.toYAML { };
  toINI = lib.generators.toINI { };
  toConf = with lib.generators; toKeyValue { mkKeyValue = mkKeyValueDefault { } " = "; };
  escapeStr = str: "'${str}'";
  ## END pkgs agnostic functions
  ## BEGIN pkgs dependent functions
  mkForPkgs = pkgs: {
    # Create a symlink of dir/file out of /nix/store (with prefix `custom_`)
    mkOutOfStoreSymlink =
      path:
      let
        path_str = toString path;
        # Filter unsafe chars
        store_filename =
          path:
          let
            safe_chars = [
              "+"
              "."
              "_"
              "?"
              "="
            ]
            ++ lib.lowerChars
            ++ lib.upperChars
            ++ lib.stringToCharacters "0123456789";
            gen_empt_lst = len: builtins.genList (_: "") (builtins.length len);
            # `builtins.replaceStrings` filters `safe_chars` out
            unsafe_chars = lib.stringToCharacters (builtins.replaceStrings safe_chars (gen_empt_lst safe_chars) path);
            safe_name = builtins.replaceStrings unsafe_chars (gen_empt_lst unsafe_chars) path;
          in
          "custom_" + safe_name;
        name = store_filename (baseNameOf path_str);
      in
      pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg path_str} $out";

    # Args to generate nixosSystem/darwinSystem
    genOsConfiguration_unwrapped =
      home-manager:
      {
        name,
        machineConfigs ? (throw "Are you forget to import `machineConfigs` in the machine's apex config?"),
        mylib,
        const,
        machinePath,
        system ? pkgs.stdenv.hostPlatform.system,
        modules,
        hmModules ? [ ],
        overlays ? [ ],
        specialArgs ? { },
      }:
      let
        special_args = {
          inherit machineConfigs mylib const;
        }
        // specialArgs;
      in
      {
        inherit system;
        specialArgs = special_args;
        # Filter out the files with `impermanence.nix` suffix. If it's not a path or string (i.e. an attribute set),
        # return true immediately to keep it
        modules =
          modules
          ++ [
            {
              nixpkgs = { inherit overlays; };
              imports = mylib.scanPath machinePath;
              networking.hostName = name;
            }
          ]
          ++ (lib.optionals ((lib.length hmModules) > 0) [
            home-manager.${if pkgs.stdenv.isDarwin then "darwinModules" else "nixosModules"}.home-manager
            {
              home-manager.backupFileExtension = "home-manager.backup";
              home-manager.extraSpecialArgs = special_args;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${const.username}".imports =
                hmModules ++ lib.optional (builtins.pathExists "${machinePath}/_hm") "${machinePath}/_hm";
            }
          ]);
      };
  };
  ## END pkgs dependent functions
}
