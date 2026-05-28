{
  lib,
  myvars,
  pkgs,
  ...
}:
{
  programs.gpg = {
    # https://www.gnupg.org/gph/en/manual/x334.html
    publicKeys = [
      {
        source = "${myvars.secretsDir}/${myvars.email}.pub.asc";
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
    sshKeys = myvars.gpgKeygrip; # Run 'gpg --export-ssh-key gpg-key!' to export public key
  };
}
