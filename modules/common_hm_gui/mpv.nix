{
  lib,
  pkgs,
  ...
}:
{
  home.shellAliases."mpv" = "mpv --player-operation-mode=pseudo-gui";
  programs.mpv = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin then
        pkgs.mpv-unwrapped # https://github.com/NixOS/nixpkgs/issues/356860
      else
        pkgs.mpv;
    scripts = lib.optionals (!pkgs.stdenv.isDarwin) [ pkgs.mpvScripts.mpris ];
    defaultProfiles = [
      "common"
      "gpu-hq"
    ];
    config = {
      # log-file = "${config.xdg.cacheHome}";

      hwdec-codecs = "all"; # Allowed all codecs, see 'mpv --vd=help'

      # Enable direct rendering, the video will be decoded directly to GPU video memory (or staging buffers). Currently
      # this enables it on AMD or NVIDIA if using OpenGL or unconditionally if using Vulkan. Using video filters of any
      # kind that write to the image data (or output newly allocated frames) will silently disable the DR code path.
      # vd-lavc-dr = true;
      # opengl-pbo = true;

      # audio-exclusive = true; # Let MPV exclusive audio device, will leave other programs have no sound
      # audio-channels = "stereo"; # Try to set 'stereo' to force dual-channel if so audio channels don't pplay properly

      # If you feel that the bgm is too loud and the character voices are small when multiple audio tracks are downmixed
      # to dual-channel, try this. https://github.com/mpv-player/mpv/issues/6563
      # audio-normalize-downmix = true;

      save-position-on-quit = true; # Save position of last playback, cannot coexist with SVP
      # The directory in which to store the "watch later" temporary files.
      # watch-later-dir = "${config.xdg.stateHome}/mpv/watch_later";
      keep-open = true; # Do not terminate when playing or seeking beyond the end of the file
      # ontop = true; # Makes the player window stay on top of other windows.

      video-sync = "display-resample"; # Resample audio to match the video
      # Maximum speed difference in percent that is applied to video with '--video-sync=display-*'
      video-sync-max-video-change = 5;
      # Reduce stuttering caused by mismatches in the video fps and display refresh rate (aka. judder). Requires
      # `--video-sync=display-*`. 2x memory usage
      interpolation = true;
      # The filter used for interpolating the temporal axis (frames). Requires --interpolation=yes. The default is
      # `oversample`. Overall, `mitchell` is smoother (certainly not good as SVP) but blurring, while `oversample` has
      # no blurring but not smooth (basically restore the 24 fps alike). Choose according to your own needs
      # tscale = "mitchell";

      # default: fruit. The error-diffusion algorithm requires large amount of shared memory to run
      # dither = "error-diffusion";
      dither-size-fruit = 7; # Set the size of the dither matrix (default: 6). Used in `--dither=fruit` mode only
      temporal-dither = true;

      ## Color correction
      # icc-profile="${config.home.homeDirectory}/sync_work/TPLCD_8AAE_AdobeRGB.icm";
      icc-profile-auto = true;
      # icc-3dlut-size=256x256x256 # Startup will slightly slower, and will increase RAM usage ~500MiB

      audio-file-auto = "fuzzy"; # Load all audio files containing the media filename
      # audio-file-paths = "audio";
      alang = "eng,en"; # Specify a prioritized list of audio languages to use, as IETF language tags

      sub-auto = "fuzzy"; # Load all subs containing the media filename
      # mpv will searches for subtitle files in these directories:
      # /path/to/video/
      # /path/to/video/sub/
      # /path/to/video/subtitles/
      # the sub configuration subdirectory (usually `~/.config/mpv/sub/`)
      sub-file-paths = "sub:subtitles";
      slang = "chi,zh-CN,sc,chs"; # Equivalent to `--alang`, for subtitle tracks
      # sub-ass-use-video-data = "none"; # Whether the subtitle aspects the video ratio, 3D rotations and blurs

      screenshot-format = "avif"; # Save screenshot as AV1 image file format
    };
    profiles = {
      "HDR_or_21:9" = {
        # NOTE: Conditions are executed in Lua code
        profile-cond = "p[\"video-params/primaries\"]==\"bt.2020\" or p[\"video-params/aspect\"]>=2.0";
        blend-subtitles = false;
        # Enables placing toptitles and subtitles in black borders when they are available. Default: no
        sub-ass-force-margins = true;
      };
      "SDR_and_16:9" = {
        profile-cond = "p[\"video-params/primaries\"]~=\"bt.2020\" and p[\"video-params/aspect\"]<2.0";
        # Blend subtitles directly onto upscaled video frames, before interpolation and/or color management (default:
        # no). Enabling this causes subtitles to be affected by `--icc-profile`, `--target-prim`, `--target-trc`,
        # `--interpolation`, `--gamma-factor` and `--glsl-shaders`. It also increases subtitle performance when using
        # `--interpolation`. The downside of enabling this is that it restricts subtitles to the visible portion of the
        # video, so you can't have subtitles shown in the black margins
        blend-subtitles = true;
        sub-ass-force-margins = false;
      };
      # Mainly on gpu-hq and Linux platform
      common = {
        profile = "gpu-hq";
        fbo-format = "rgba32f";
        vo = "gpu-next";
        # vo = "dmabuf-wayland";
        gpu-api = "vulkan";
        vulkan-device = lib.mkDefault ""; # See `mpv --vulkan-device=help`
        hwdec = "auto";
        ao = lib.mkDefault "pipewire";
      };
      Low = {
        # Currently mpv.nix doesn't support hm.dag,
        # see https://github.com/nix-community/home-manager/blob/master/modules/programs/mpv.nix
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "240p/360p, enable scalling twice to achieve 4x";
        profile-cond = "p[\"video-params/w\"]<=678 and p[\"video-params/h\"]<=381"; # 1080 * 1.414213 / 4 = 381.8
        profile = "common";
        glsl-shaders-append = [
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/KrigBilateral.glsl"
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/nnedi3-nns32-win8x6.hook"
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/nnedi3-nns32-win8x6.hook"
        ];
      };
      SD = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "480p/576p";
        # 1080 / 16 * 9 = 607.5
        profile-cond =
          "(p[\"video-params/w\"]<1080 and p[\"video-params/h\"]<608)"
          + " and (p[\"video-params/w\"]>678 or p[\"video-params/h\"]>381)";
        profile = "common";
        glsl-shaders-append = [
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/KrigBilateral.glsl"
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/nnedi3-nns64-win8x6.hook"
        ];
      };
      HD30 = {
        # 1080 * 1.414213 / 2 = 763.7
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "640p/720p 30fps";
        profile-cond =
          "(p[\"video-params/w\"]<1358 and p[\"video-params/h\"]<764)"
          + " and (p[\"video-params/w\"]>=1080 or p[\"video-params/h\"]>=608)"
          + " and p[\"estimated-vf-fps\"]<31";
        profile = "common";
        glsl-shaders-append = [
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/KrigBilateral.glsl"
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/nnedi3-nns32-win8x6.hook"
        ];
      };
      HD60 = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "640p/720p 60fps";
        profile-cond =
          "(p[\"video-params/w\"]<1358 and p[\"video-params/h\"]<764)"
          + " and (p[\"video-params/w\"]>=1080 or p[\"video-params/h\"]>=608)"
          + " and p[\"estimated-vf-fps\"]>=31";
        profile = "common";
        glsl-shaders-append = [
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/KrigBilateral.glsl"
          # For SSimSuperRes it is recommend to turn off sigmoid-upscaling
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/SSimSuperRes.glsl"
        ];
        # When upscaling, use a sigmoidal color transform to avoid emphasizing ringing artifact.
        # Default to yes in profile `gpu-hq`
        sigmoid-upscaling = false;
      };
      KrigBilateral = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile = "common";
        glsl-shaders-append = "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/KrigBilateral.glsl";
      };
      FHD = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "1080p";
        profile-cond =
          "(p[\"video-params/w\"]<=1920 and p[\"video-params/h\"]<=1080)"
          + " and (p[\"video-params/w\"]>=1358 or p[\"video-params/h\"]>=764)";
        profile = "KrigBilateral";
      };
      UHD30 = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "4k 30fps: use SSIM to downscale";
        profile-cond = "(p[\"video-params/w\"]>2560 or p[\"video-params/h\"]>1440) and p[\"estimated-vf-fps\"]<31";
        profile = "common";
        glsl-shaders-append =
          # NOTE: SSimDownscaler requires turning off linear-dewnscaling
          "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders/SSimDownscaler.glsl";
        # Scale in linear light when downscaling. It should only be used with a `--fbo-format` that has at least 16 bit
        # precision. This option has no effect on HDR content. Default to yes in profile `gpu-hq`
        linear-downscaling = false;
      };
      UHD60 = {
        "#\nglsl-shaders-clr\n#" = "Placeholder";
        profile-desc = "4k high fps: use w.o. any glsl-shaders";
        profile-cond = "(p[\"video-params/w\"]>1920 or p[\"video-params/h\"]>1080) and p[\"estimated-vf-fps\"]>=31";
        profile = "common";
        # If playing 4k videos with a 1080p monitor, consider try
        # https://gist.github.com/bjin/15f307e7a1bdb55842bbb663ee1950ed
        # glsl-shaders-append = "~~/shaders/acme-0.5x.hook";

        # Doesn't need chroma upscaling anymore. e.g. with a 1080p monitor mpv will do chroma conversion with precision
        # of 1080p level instead of 2160p level
        fbo-format = "auto";
      };
    };
  };
}
