# TODO: remove
{
  wayland.windowManager.hyprland.settings.curve = [
    {
      # https://easings.net/#easeOutQuint
      _args = [
        "easeOutQuint"
        {
          type = "bezier";
          points = [
            [
              0.23
              1
            ]
            [
              0.32
              1
            ]
          ];
        }
      ];
    }
    {
      # https://cubic-bezier.com/#0,0,1,1
      _args = [
        "linear"
        {
          type = "bezier";
          points = [
            [
              0
              0
            ]
            [
              1
              1
            ]
          ];
        }
      ];
    }
    {
      # https://cubic-bezier.com/#.5,.5,.75,1
      _args = [
        "almostLinear"
        {
          type = "bezier";
          points = [
            [
              0.5
              0.5
            ]
            [
              0.75
              1.0
            ]
          ];
        }
      ];
    }
    {
      # https://cubic-bezier.com/#.15,0,.1,1
      _args = [
        "quick"
        {
          type = "bezier";
          points = [
            [
              0.15
              0
            ]
            [
              0.1
              1
            ]
          ];
        }
      ];
    }
    {
      _args = [
        "easy"
        {
          type = "spring";
          mass = 1;
          stiffness = 71.2633;
          dampening = 15.8273644;
        }
      ];
    }
  ];

  animation = [
    {
      leaf = "global";
      enabled = true;
      speed = 10;
      bezier = "default";
    }
    {
      leaf = "border";
      enabled = true;
      speed = 5.39;
      bezier = "easeOutQuint";
    }
    {
      leaf = "windows";
      enabled = true;
      speed = 4.79;
      spring = "easy";
    }
    {
      leaf = "border";
      enabled = true;
      speed = 5.39;
      bezier = "easeOutQuint";
    }
    {
      leaf = "windowsIn";
      enabled = true;
      speed = 4.1;
      spring = "easy";
      style = "popin 87%";
    }
    {
      leaf = "windowsOut";
      enabled = true;
      speed = 1.49;
      bezier = "linear";
      style = "popin 87%";
    }
    {
      leaf = "fadeIn";
      enabled = true;
      speed = 1.73;
      bezier = "almostLinear";
    }
    {
      leaf = "fadeOut";
      enabled = true;
      speed = 1.46;
      bezier = "almostLinear";
    }
    {
      leaf = "fade";
      enabled = true;
      speed = 3.03;
      bezier = "quick";
    }
    {
      leaf = "layers";
      enabled = true;
      speed = 3.81;
      bezier = "easeOutQuint";
    }
    {
      leaf = "layersIn";
      enabled = true;
      speed = 4;
      bezier = "easeOutQuint";
      style = "fade";
    }
    {
      leaf = "layersOut";
      enabled = true;
      speed = 1.5;
      bezier = "linear";
      style = "fade";
    }
    {
      leaf = "fadeLayersIn";
      enabled = true;
      speed = 1.79;
      bezier = "almostLinear";
    }
    {
      leaf = "fadeLayersOut";
      enabled = true;
      speed = 1.39;
      bezier = "almostLinear";
    }
    {
      leaf = "workspaces";
      enabled = true;
      speed = 1.94;
      bezier = "almostLinear";
      style = "fade";
    }
    {
      leaf = "workspacesIn";
      enabled = true;
      speed = 1.21;
      bezier = "almostLinear";
      style = "fade";
    }
    {
      leaf = "workspacesOut";
      enabled = true;
      speed = 1.94;
      bezier = "almostLinear";
      style = "fade";
    }
    {
      leaf = "zoomFactor";
      enabled = true;
      speed = 7;
      bezier = "quick";
    }
  ];
}
