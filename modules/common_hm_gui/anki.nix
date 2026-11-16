{
  const,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  anki_pkg =
    if isDarwin then
      # pkgs.anki fails on aarch64-darwin because its `anki-mac-helper`
      # dependency does not build. Fix pending in
      # https://github.com/NixOS/nixpkgs/pull/584031
      pkgs.anki-bin
    else
      # The nixpkgs build links Qt 6.12, which implements the Wayland
      # text-input-v3 protocol. niri (26.04+) supports it, so fcitx5 is used
      # natively and forcing QT_IM_MODULE=fcitx is no longer needed.
      pkgs.anki;
in
{
  sops.secrets.anki_sync_key = { };
  # Installed directly until `programs.anki.enable` is switched on below.
  home.packages = lib.optionals (!config.programs.anki.enable) [ anki_pkg ];

  programs.anki = {
    # Enabling this makes Home Manager:
    #   - replace ~/.local/share/Anki2/prefs21.db with a generated one (the old
    #     file is kept as *.home-manager.backup, but syncKey is lost until the
    #     next AnkiWeb login), and
    #   - point ANKI_ADDONS at a read-only store path, hiding runtime add-ons.
    enable = !isDarwin;

    # Must stay `pkgs.anki` while enabled: the module requires a package that
    # provides `withAddons`, which `anki-bin` does not.
    package = pkgs.anki;

    language = "en_US";
    uiScale = 1.5;

    # QtWebEngine on NVIDIA + Wayland cannot use GBM and falls back to Vulkan,
    # which aborts in NativeSkiaOutputDeviceVulkan::texture. The OpenGL ("auto")
    # driver therefore renders a black window. Pin software rendering until the
    # Qt issue is fixed. While `enable` is off, the live setting lives in
    # ~/.local/share/Anki2/gldriver6.
    videoDriver = "software";

    addons = [
      pkgs.ankiAddons.review-heatmap # 1771074083

      # 1436550454
      (
        (pkgs.anki-utils.buildAnkiAddon (finalAttrs: {
          pname = "awesometts";
          version = "1.89.5";
          src = pkgs.fetchFromGitHub {
            owner = "Vocab-Apps";
            repo = "anki-awesome-tts";
            tag = "v${finalAttrs.version}";
            hash = "sha256-e5Sj9z3rk8Zw2jfKunKepelS0r5xhEbuphebvE5nzHE=";
          };

          # The add-on creates user_files/cache and addon.log inside its own
          # directory at import time, which is read-only in the Nix store. Point
          # its writable state at the (persisted) Anki data directory instead.
          #
          # It also derives the Anki config name by checking whether its own path
          # contains the AnkiWeb ID, which never matches under Nix; use the module
          # name so getConfig() finds the add-on instead of returning None.
          postPatch = ''
            substituteInPlace awesometts/paths.py \
              --replace-fail "USER_FILES = os.path.join(ROOT, 'user_files')" \
              "USER_FILES = os.path.join(os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share')), 'Anki2', 'awesometts')" \
              --replace-fail "LOG = os.path.join(ADDON, 'addon.log')" \
              "LOG = os.path.join(USER_FILES, 'addon.log')"
            substituteInPlace awesometts/config.py \
              --replace-fail "CONFIG_ADDON_NAME = 'anki-awesome-tts'" \
              "CONFIG_ADDON_NAME = __name__.split('.')[0]" \
              --replace-fail "if ANKIWEB_ADDON_ID in __file__:" \
              "if False:" \
              --replace-fail "    CONFIG_ADDON_NAME = ANKIWEB_ADDON_ID" \
              "    pass"
          '';

          meta = {
            description = "AwesomeTTS text-to-speech add-on for Anki";
            homepage = "https://github.com/Vocab-Apps/anki-awesome-tts";
            license = lib.licenses.gpl3Plus;
          };
        })).withConfig
        {
          # Pre-seed the config so the add-on does not try to write meta.json into
          # the read-only store during its first import.
          config.user_uuid = "d7f3f59ee4b449cf9b55bd5e84fad701";
        }
      )

      # NOTE: Jlab (2110939339) has no public source
    ];

    profiles."User 1" = {
      default = true;
      sync = {
        username = const.email;
        keyFile = config.sops.secrets.anki_sync_key.path;
        url = "https://sync25.ankiweb.net/";
        autoSync = true;
        syncMedia = true;
        autoSyncMediaMinutes = 15;
        networkTimeout = 60;
      };
    };
  };
}
