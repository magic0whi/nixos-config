_: {
  environment.persistence."/persistent".files = [
    {
      file = "/etc/dm_keyfile.key";
      parentDirectory = {
        mode = "0700";
      };
    }
  ];
}
