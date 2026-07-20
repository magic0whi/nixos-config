{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."aerospace/ghostty-actions.js".text = ''
    #!/usr/bin/env osascript -l JavaScript
    ObjC.import('Foundation')
    const argv = $.NSProcessInfo.processInfo.arguments.js
    const system_events = Application('System Events');
    const app_path = '${config.programs.ghostty.package}/Applications/Ghostty.app';

    function quick_term() {
      const ghostty = system_events.processes.byName('Ghostty');
      const menu_bar_view_quick_term = ghostty.menuBars[0].menuBarItems['View'].menus[0].menuItems['Quick Terminal'];
      menu_bar_view_quick_term.click();
    }
    function new_window() {
      const ghostty = system_events.processes.byName('Ghostty');
      const menu_bar_file_new_window = ghostty.menuBars[0].menuBarItems['File'].menus[0].menuItems['New Window'];
      menu_bar_file_new_window.click();
    }
    function run(argv) {
      var ghostty = null;
      switch (Application(app_path).running()) {
        case false: ghostty = Application(app_path); delay(0.2); break;
        case true: ghostty = Application(app_path);
      }
      argv.forEach((arg, idx) => {
        switch(arg) {
          case "1": ghostty.activate(); break; // Focus Ghostty
          case "2": quick_term(); break; // Quich Terminal
          case "3": new_window();
        }
      });
    }
  '';
  xdg.configFile."aerospace/finder-actions.js".text = ''
    #!/usr/bin/env osascript -l JavaScript
    ObjC.import('Foundation')
    const argv = $.NSProcessInfo.processInfo.arguments.js
    const system_events = Application('System Events');
    const app_path = 'Finder';

    function new_window() {
      const finder_proc = system_events.processes.byName('Finder');
      const menu_bar_file_new_finder_window = finder_proc.menuBars[0].menuBarItems['File'].menus[0].menuItems['New Finder Window'];
      menu_bar_file_new_finder_window.click();
    }
    function run(argv) {
      var finder = null;
      switch (Application(app_path).running()) {
        case false: finder = Application(app_path); delay(0.2); break;
        case true: finder = Application(app_path);
      }
      argv.forEach((arg, idx) => {
        switch(arg) {
          case "1": finder.activate(); break; // Focus/Launch Finder
          case "2": new_window();
        }
      });
    }
  '';
  ## BEGIN jankyborders.nix
  # Highlight focused windows with colored borders
  services.jankyborders = {
    enable = true;
    settings = {
      active_color = "0xffe1e3e4";
      inactive_color = "0xff494d64";
      width = 5.0;
    };
  };
  ## END jankyborders.nix
  ## BEGIN xdg.nix
  xdg.enable = true; # Enable management of XDG base directories on macOS
  ## END xdg.nix
  ## BEGIN shell.nix
  home.shellAliases = {
    Ci = "pbcopy";
    Co = "pbpaste";
  };
  ## END shell.nix
  ## BEGIN associations.nix
  home.activation.mpv_associations =
    let
      duti_exe = lib.getExe' pkgs.duti "duti";
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Set UTIs
      ${duti_exe} -s io.mpv public.movie viewer
      # Set file extensions
      ${duti_exe} -s io.mpv .mkv viewer
      ${duti_exe} -s io.mpv .mp4 viewer
      ${duti_exe} -s com.google.Chrome .webm viewer
      ${duti_exe} -s com.apple.Preview .heic viewer
    '';
  ## END associations.nix
}
