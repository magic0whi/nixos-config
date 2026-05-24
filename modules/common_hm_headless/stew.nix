{
  myvars,
  pkgs,
  lib,
  ...
}: {
  # This value determines the Home Manager release that your configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for a list of state
  # version changes in each release.
  home.stateVersion = myvars.nixos_state_version;
  programs.home-manager.enable = true; # Let Home Manager install and manage itself.
  programs.rclone.enable = true;
  ## BEGIN syncthing.nix
  services.syncthing.enable = lib.mkDefault true;
  systemd.user.services.syncthing.environment.STNODEFAULTFOLDER = "true";
  launchd.agents.syncthing.config.EnvironmentVariables.STNODEFAULTFOLDER = "true";
  ## END syncthing.nix
  ## BEGIN pip.nix
  # Use mirror for pip install
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    index-url = https://mirror.nju.edu.cn/pypi/web/simple
    format = columns
  '';
  ## END pip.nix
  ## BEGIN btop.nix
  # Alternative to htop/nmon
  programs.btop = {
    enable = true;
    settings.theme_background = false; # Make btop transparent
  };
  ## END btop.nix
  ## BEGIN yazi.nix
  # Terminal file manager
  programs.yazi = {
    # NOTE: Home Manager provides `y` to allow changing working directory when exitig Yazi
    enable = true;
    settings.mgr = {
      linemode = "mtime";
      show_hidden = true;
      sort_dir_first = true;
    };
    plugins.drag = pkgs.yaziPlugins.drag;
    plugins.recycle-bin =
      if pkgs.stdenv.isDarwin
      then pkgs.emptyFile
      else pkgs.yaziPlugins.recycle-bin;
    initLua =
      if pkgs.stdenv.isDarwin
      then null
      else ''require("recycle-bin"):setup()'';
    extraPackages = with pkgs; [ripdrag trash-cli ueberzugpp];
    keymap = {
      mgr.prepend_keymap = [
        {
          on = ["<C-s>"];
          run = "plugin drag";
          desc = "Drag Files";
        }
        {
          on = ["R" "b"];
          run = "plugin recycle-bin";
          desc = "Open Trash";
        }
        {
          on = ["g" "w"];
          run = "cd ~/Works";
          desc = "Go ~/Works";
        }
        {
          on = ["g" "a"];
          run = "cd ~/Works/AI/ai_instructions";
          desc = "~/Works/AI/ai_instructions";
        }
      ];
    };
  };
  ## END yazi.nix
  ## BEGIN direnv.nix
  # programs.direnv = {
  #   enable = true;
  #   nix-direnv.enable = true;
  # };
  ## END direnv.nix
  ## BEGIN neovim.nix
  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  # };
  ## END neovim.nix
  ## BEGIN gpg.nix
  programs.gpg = {
    # https://www.gnupg.org/gph/en/manual/x334.html
    publicKeys = [
      {
        source = "${myvars.secrets_dir}/${myvars.useremail}.pub.asc";
        trust = 5; # Ultimate trust
      }
    ];
    enable = true;
    # $GNUPGHOME/trustdb.gpg stores all the trust level you specified in `programs.gpg.publicKeys` option. If set
    # `mutableTrust` to false, the path $GNUPGHOME/trustdb.gpg will be overwritten on each activation. Thus we can only
    # update trsutedb.gpg via home-manager
    mutableTrust = true;
    # $GNUPGHOME/pubring.kbx stores all the public keys you specified in `programs.gpg.publicKeys` option. If set
    # `mutableKeys` to false, the path $GNUPGHOME/pubring.kbx will become an immutable link to the Nix store, denying
    # modifications. Thus we can only update pubring.kbx via home-manager
    mutableKeys = true;
    # This configuration is based on the tutorial https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1
    # , it allows for a robust setup
    settings = {
      no-greeting = true; # Get rid of the copyright notice
      no-emit-version = true; # Disable inclusion of the version string in ASCII armored output
      no-comments = false; # Do not write comment packets
      # Export the smallest key possible. This removes all signatures except the most recent self-signature on each user
      # ID
      export-options = "export-minimal";
      keyid-format = "0xlong"; # Display long key IDs
      with-fingerprint = true; # List all keys (or the specified ones) along with their fingerprints
      list-options = "show-uid-validity"; # Display the calculated validity of user IDs during key listings
      verify-options = "show-uid-validity show-keyserver-urls";
      personal-cipher-preferences = "AES256"; # Select the strongest cipher
      personal-digest-preferences = "SHA512"; # Select the strongest digest
      # This preference list is used for new keys and becomes the default for "setpref" in the edit menu
      default-preference-list = "SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed";

      cipher-algo = "AES256"; # Use the strongest cipher algorithm
      digest-algo = "SHA512"; # Use the strongest digest algorithm
      cert-digest-algo = "SHA512"; # Message digest algorithm used when signing a key
      compress-algo = "ZLIB"; # Use RFC-1950 ZLIB compression

      disable-cipher-algo = "3DES"; # Disable weak algorithm
      weak-digest = "SHA1"; # Treat the specified digest algorithm as weak

      # The cipher algorithm for symmetric encryption for symmetric encryption with a passphrase
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512"; # The digest algorithm used to mangle the passphrases for symmetric encryption
      s2k-mode = "3"; # Selects how passphrases for symmetric encryption are mangled
      # Specify how many times the passphrases mangling for symmetric encryption is repeated
      s2k-count = "65011712";
    };
  };
  services.gpg-agent = {
    enable = true;
    pinentry.package = lib.mkDefault pkgs.pinentry-curses;
    enableSshSupport = true;
    defaultCacheTtl = 4 * 60 * 60; # 4 hours
    sshKeys = myvars.gpg2ssh_keygrip; # Run 'gpg --export-ssh-key gpg-key!' to export public key
  };
  ## END gpg.nix
  ## BEGIN catppuccin.nix
  # Enable Catppuccin globally
  catppuccin = {
    enable = lib.mkDefault true;
    accent = myvars.catppuccin_accent;
    flavor = myvars.catppuccin_flavor;
  };
  ## END catppuccin.nix
}
