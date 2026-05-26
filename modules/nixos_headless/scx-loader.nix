_: {
  services.scx-loader = {
    enable = true;
    config = {
      default_sched = "scx_lavd";
      scheds."scx_lavd".auto_mode = [ "--autopower" ];
    };
  };
}
