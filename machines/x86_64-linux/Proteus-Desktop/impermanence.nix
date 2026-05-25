_: {
  environment.persistence."/persistent".files = [
    {
      # TODO: Unsafe
      file = "/etc/dm_keyfile.key";
      parentDirectory = {
        mode = "0700";
      };
    }
  ];
}
