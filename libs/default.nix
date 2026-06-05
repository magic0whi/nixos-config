{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  ## BEGIN pkgs agnostic functions
  # Use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;

  scanPath =
    p:
    map (fn: p + "/${fn}") (
      builtins.attrNames (
        lib.filterAttrs
          # Exclude if `_` prefix, include directories and *.nix, exclude default.nix
          (e: t: !(lib.hasPrefix "_" e) && ((t == "directory") || ((lib.hasSuffix ".nix" e) && (e != "default.nix"))))
          (builtins.readDir p)
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

  genDeployNode = ifaces: nixos_system: {
    hostname =
      let
        ts_iface = builtins.elemAt ifaces 0;
        et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
      in
      et_iface.ipv4 or ts_iface.ipv4 or nixos_system.config.networking.hostName;
    sshUser = "root";
    interactiveSudo = false; # Since we use 'root' user to ssh
    profiles.system = {
      path = inputs.deploy-rs.lib.${nixos_system.pkgs.stdenv.hostPlatform.system}.activate.nixos nixos_system;
      user = "root";
    };
  };
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
    genOsConfiguration =
      {
        name,
        machineConfigs ? (throw "Are you forget to import `machineConfigs` in the machine's apex config?"),
        mylib,
        myvars,
        nixpkgs_modules,
        hm_modules ? [ ],
        machine_path,
        system ? pkgs.stdenv.hostPlatform.system,
      }:
      let
        inherit (inputs)
          catppuccin
          disko
          home-manager
          i915-sriov-dkms
          impermanence
          lanzaboote
          lix-module
          niks3
          sops-nix
          ;
        specialArgs = inputs // {
          inherit machineConfigs mylib myvars;
        };
      in
      {
        inherit system specialArgs;
        # Filter out the files with `impermanence.nix` suffix. If it's not a path or string (i.e. an attribute set),
        # return true immediately to keep it
        modules =
          nixpkgs_modules
          ++ (
            if pkgs.stdenv.isDarwin then
              [
                lix-module.darwinModules.lixFromNixpkgs
                sops-nix.darwinModules.sops
              ]
            else
              [
                disko.nixosModules.disko
                i915-sriov-dkms.nixosModules.default
                impermanence.nixosModules.impermanence
                lanzaboote.nixosModules.lanzaboote
                lix-module.nixosModules.default
                niks3.nixosModules.niks3
                niks3.nixosModules.niks3-auto-upload
                sops-nix.nixosModules.sops
              ]
          )
          ++ [
            {
              imports = mylib.scanPath machine_path;
              networking.hostName = name;
            }
          ]
          ++ (lib.optionals ((lib.length hm_modules) > 0) [
            home-manager.${if pkgs.stdenv.isDarwin then "darwinModules" else "nixosModules"}.home-manager
            {
              home-manager.backupFileExtension = "home-manager.backup";
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [
                catppuccin.homeModules.catppuccin
                sops-nix.homeManagerModules.sops
              ];
              home-manager.users."${myvars.username}".imports =
                hm_modules ++ lib.optional (builtins.pathExists (machine_path + "/_hm")) (machine_path + "/_hm");
            }
          ]);
      };
  };
  ## END pkgs dependent functions
}
