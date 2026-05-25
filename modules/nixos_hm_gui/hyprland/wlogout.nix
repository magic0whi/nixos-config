# Logout menu
{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  options.programs.wlogout = {
    wrapper_script = lib.mkOption {
      type = lib.types.path;
      description = "Path to the wlogout wrapper script";
      default = pkgs.writeShellScript "wlogout" ''
        set -eufo pipefail

        if ! pidof wlogout > /dev/null; then
          wlogout \
            --column-spacing 20 \
            --row-spacing 20 \
            --margin-top 200 \
            --margin-bottom 200 \
            --margin-left 150 \
            --margin-right 150
        else
          pkill wlogout || true
        fi
      '';
    };
    share = lib.mkOption {
      type = lib.types.path;
      description = "Path to wlogout assets directory (e.g., icons)";
      default = ./_assets/wlogout;
    };
  };
  config = {
    programs.wlogout = {
      enable = true;
      layout = [
        # Align with those logout bind configs from Hyprland
        {
          label = "lock";
          action = "loginctl lock-session";
          text = "Lock";
          keybind = "z";
        }
        {
          label = "logout";
          action = "loginctl terminate-user $USER";
          text = "Logout";
          keybind = "q";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "w";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "e";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "t";
        }
      ];
      style = ''
        /** ********** Fonts ********** **/
        * {font-family: "${myvars.monospace.name}", sans-serif; font-size: 14px; font-weight: bold;}

        /** ********** Main Window ********** **/
        window {background-color: #1e1e2e;}

        /** ********** Buttons ********** **/
        button {
          background-color: #242434;
          color: #ffffff;
          border: 2px solid #282838;
          border-radius: 20px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 35%;
        }
        button:focus, button:active, button:hover {background-color: #89b4fa; outline-style: none;}

        /** ********** Icons ********** **/
        #lock {background-image: image(
          url("${config.programs.wlogout.share}/icons/lock.png"), url("/usr/share/wlogout/icons/lock.png")
        );}
        #logout {background-image: image(
          url("${config.programs.wlogout.share}/icons/logout.png"), url("/usr/share/wlogout/icons/logout.png")
        );}
        #suspend {background-image: image(
          url("${config.programs.wlogout.share}/icons/suspend.png"), url("/usr/share/wlogout/icons/suspend.png")
        );}
        #hibernate {background-image: image(
          url("${config.programs.wlogout.share}/icons/hibernate.png"), url("/usr/share/wlogout/icons/hibernate.png")
        );}
        #reboot {background-image: image(
          url("${config.programs.wlogout.share}/icons/reboot.png"), url("/usr/share/wlogout/icons/reboot.png")
        );}
        #shutdown {background-image: image(
          url("${config.programs.wlogout.share}/icons/shutdown.png"), url("/usr/share/wlogout/icons/shutdown.png")
        );}
      '';
    };
  };
}
