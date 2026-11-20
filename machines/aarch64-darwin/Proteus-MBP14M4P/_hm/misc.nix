{
  config,
  const,
  lib,
  pkgs,
  ...
}:
{
  ## BEGIN llama-server.nix
  sops.secrets.llama-server_api_token.sopsFile = const.secretsDir + "/services/llama-server.sops.yaml";

  # Unified memory caps at an 8B Q4 (~5 GB) as the always-on default; a 14B Q4
  # needs ~9 GB and is a deliberate swap, not a second service.
  launchd.agents.llama-server = {
    enable = true;
    config = {
      ProgramArguments = lib.singleton (
        pkgs.writeShellScript "llama-server" ''
          set -eu
          # -a = API model name; -ngl 99 = all layers on Metal; -c 8192 = context;
          # -fa on = flash attention; --cache-type-k/v q8_0 = half-size KV cache;
          # --jinja = use the GGUF chat template; --reasoning off = no Qwen3 thinking.
          exec ${pkgs.llama-cpp}/bin/llama-server \
            -m ${
              # 5.03 GB Q4_K_M. Mirror first (direct HF is ~1 MB/s here), HF as fallback.
              # sha256: d98cdcbd03e17ce47681435b5150e34c1417f50b5c0019dd560e4882c5745785
              pkgs.fetchurl {
                name = "Qwen3-8B-Q4_K_M.gguf";
                urls = [
                  "https://hf-mirror.com/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
                  "https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf"
                ];
                hash = "sha256-2YzcvQPhfOR2gUNbUVDjTBQX9QtcABndVg5IgsV0V4U=";
              }
            } \
            -a qwen3-8b \
            --host 0.0.0.0 --port 8080 \
            --api-key-file ${config.sops.secrets.llama-server_api_token.path} \
            -ngl 99 -c 8192 -fa on \
            --cache-type-k q8_0 --cache-type-v q8_0 \
            --jinja --reasoning off
        ''
      );
      KeepAlive = true;
      RunAtLoad = true;
      ThrottleInterval = 10;
      ProcessType = "Interactive"; # keep App Nap from throttling inference
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/llama-server.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/llama-server.log";
    };
  };
  ## END llama-server.nix
  ## BEGIN aerospace.nix
  programs.aerospace.settings.workspace-to-monitor-force-assignment = {
    "7" = [ "C340SCA" ];
    "8" = [ "C340SCA" ];
    "9" = [ "RTK UHD HDR" ];
    "0" = [ "RTK UHD HDR" ];
  };
  ## END aerospace.nix
  ## BEGIN mpv.nix
  programs.mpv.profiles.common = {
    vulkan-device = "Apple M4 Pro";
    ao = "avfoundation";
  };
  ## END mpv.nix
}
