{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  ## BEGIN pkgs agnostic functions
  # Use path relative to the root of the project
  relative_to_root = lib.path.append ../.;

  scan_path =
    p:
    map (fn: p + "/${fn}") (
      builtins.attrNames (
        lib.filterAttrs
          # Exclude if `_` prefix, include directories and *.nix, exclude default.nix
          (e: t: !(lib.hasPrefix "_" e) && ((t == "directory") || ((lib.hasSuffix ".nix" e) && (e != "default.nix"))))
          (builtins.readDir p)
      )
    );
  get_uri_port =
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

  gen_deploy-rs_node = ifaces: nixos_system: {
    hostname =
      let
        ts_iface = builtins.elemAt ifaces 0;
        et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
      in
      et_iface.ipv4 or ts_iface.ipv4 or nixos_system.config.networking.hostName;
    # if et_iface ? ipv4
    # then et_iface.ipv4
    # else if ts_iface ? ipv4
    # then ts_iface.ipv4
    # else nixos_system.config.networking.hostName;
    sshUser = "root";
    interactiveSudo = false; # Since we use 'root' user to ssh
    profiles.system = {
      path = inputs.deploy-rs.lib.${nixos_system.pkgs.stdenv.hostPlatform.system}.activate.nixos nixos_system;
      user = "root";
    };
  };
  ## END pkgs agnostic functions
  ## BEGIN pkgs dependent functions
  mk_for_pkgs = pkgs: {
    # Create a symlink of dir/file out of /nix/store (with prefix `custom_`)
    mk_out_of_store_symlink =
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
            gen_empt_lst = len: builtins.genList (e: "") (builtins.length len);
            # `builtins.replaceStrings` filters `safe_chars` out
            unsafe_chars = lib.stringToCharacters (builtins.replaceStrings safe_chars (gen_empt_lst safe_chars) path);
            safe_name = builtins.replaceStrings unsafe_chars (gen_empt_lst unsafe_chars) path;
          in
          "custom_" + safe_name;
        name = store_filename (baseNameOf path_str);
      in
      pkgs.runCommandLocal name { } "ln -s ${lib.escapeShellArg path_str} $out";

    # Args to generate nixosSystem/darwinSystem
    gen_system_args =
      {
        name,
        mylib,
        myvars,
        nixpkgs_modules,
        hm_modules ? [ ],
        machine_path,
        generate_iso ? false,
        system ? pkgs.stdenv.hostPlatform.system,
      }:
      let
        inherit (inputs)
          home-manager
          impermanence
          lanzaboote
          sops-nix
          catppuccin
          disko
          i915-sriov-dkms
          ;
        specialArgs = inputs // {
          inherit mylib myvars;
        };
      in
      {
        inherit system specialArgs;
        # Filter out the files with `impermanence.nix` suffix. If it's not a path or string (i.e. an attribute set),
        # return true immediately to keep it
        modules =
          (
            if generate_iso then
              builtins.filter (p: !(builtins.isPath p || builtins.isString p) || !lib.hasSuffix "impermanence.nix" p) nixpkgs_modules
            else
              nixpkgs_modules
          ) # Must wrapped by brace, otherwiese ISO branch skips the later appended modules below
          ++ (
            if pkgs.stdenv.isDarwin then
              [ sops-nix.darwinModules.sops ]
            else
              [
                sops-nix.nixosModules.sops
                lanzaboote.nixosModules.lanzaboote
                catppuccin.nixosModules.catppuccin
                disko.nixosModules.disko
                i915-sriov-dkms.nixosModules.default
              ]
              ++ (lib.optional (!generate_iso) impermanence.nixosModules.impermanence)
          )
          ++ [
            {
              imports =
                let
                  all_machine_files = mylib.scan_path machine_path;
                in
                if generate_iso then builtins.filter (p: !lib.hasSuffix "impermanence.nix" p) all_machine_files else all_machine_files;
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
              home-manager.users."${myvars.username}".imports = hm_modules ++ [ (machine_path + "/_hm") ];
            }
          ]);
      };
  };
  ## END pkgs dependent functions
}
