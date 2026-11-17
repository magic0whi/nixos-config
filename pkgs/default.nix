{ pkgs }:
{
  fetch-authelia-token = pkgs.writeShellApplication {
    name = "fetch-authelia-token";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    text = ''
      fetch_authelia_token() {
        local client_id="$1"
        local client_secret_file="$2"
        local audience="$3"
        local resource="$4"
        local auth_url="$5"

        # Accept a full base URL or a bare host, with or without a trailing slash.
        while [[ "$auth_url" == */ ]]; do
          auth_url="''${auth_url%/}"
        done
        [[ "$auth_url" == *://* ]] || auth_url="https://$auth_url"
        if [[ ! "$auth_url" =~ ^https?://[^/]+ ]]; then
          echo "invalid Authelia URL: $auth_url" >&2
          return 2
        fi

        local -a grant_args=()
        if [[ -n "$resource" ]]; then
          grant_args+=(-d "resource=$resource")
        else
          grant_args+=(-d "audience=$audience")
        fi

        echo "Fetching fresh token from Authelia via client_credentials..." >&2

        curl -fsX POST \
          -H 'Content-Type: application/x-www-form-urlencoded' \
          -u "$client_id:$(<"$client_secret_file")" \
          -d 'grant_type=client_credentials' \
          -d 'scope=authelia.bearer.authz' \
          "''${grant_args[@]}" \
          "$auth_url/api/oidc/token" \
          | jq -er '.access_token'

        echo "Bearer token retrieved successfully." >&2
      }

      usage() {
        echo "Usage: $(basename "$0") --client-id ID --client-secret-file FILE (--audience AUDIENCE | --resource RESOURCE) --auth-url URL" >&2
        echo "Values may also be supplied with AUTHELIA_CLIENT_ID, AUTHELIA_CLIENT_SECRET_FILE, AUTHELIA_AUDIENCE, AUTHELIA_RESOURCE, and AUTHELIA_AUTH_URL." >&2
        echo "URL is the Authelia base URL, e.g. https://auth.example.com (the scheme is optional)." >&2
        echo "Use --resource for forward-auth protected URLs: since Authelia 4.39.21" >&2
        echo "audiences match exactly (path included), while resources allow path prefixes." >&2
      }

      client_id="''${AUTHELIA_CLIENT_ID:-}"
      client_secret_file="''${AUTHELIA_CLIENT_SECRET_FILE:-}"
      audience="''${AUTHELIA_AUDIENCE:-}"
      resource="''${AUTHELIA_RESOURCE:-}"
      auth_url="''${AUTHELIA_AUTH_URL:-}"

      while (($# > 0)); do
        case "$1" in
          --client-id)
            client_id="$2"
            shift 2
            ;;
          --client-secret-file)
            client_secret_file="$2"
            shift 2
            ;;
          --audience)
            audience="$2"
            shift 2
            ;;
          --resource)
            resource="$2"
            shift 2
            ;;
          --auth-url)
            auth_url="$2"
            shift 2
            ;;
          -h | --help)
            usage
            exit 0
            ;;
          *)
            usage
            exit 2
            ;;
        esac
      done

      : "''${client_id:?client ID is required}"
      : "''${client_secret_file:?client secret file is required}"
      : "''${auth_url:?auth URL is required}"

      if [[ -n "$audience" && -n "$resource" ]]; then
        echo "--audience and --resource are mutually exclusive" >&2
        exit 2
      fi
      if [[ -z "$audience" && -z "$resource" ]]; then
        echo "one of --audience or --resource is required" >&2
        exit 2
      fi

      fetch_authelia_token "$client_id" "$client_secret_file" "$audience" "$resource" "$auth_url"
    '';
  };

  flatten-symlinks = pkgs.writeShellApplication {
    name = "flatten-symlinks";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if [ $# -eq 0 ]; then
        echo "Usage: $(basename "$0") <file1> [file2 ...]" >&2
        exit 1
      fi

      for symlink in "$@"; do
          # Skip if it doesn't exist or is not a symlink
          if [ ! -L "$symlink" ]; then
              continue
          fi

          name=$(basename "$symlink")
          target=$(readlink -f "$symlink")

          rm "$symlink"

          cp -L "$target" "$symlink"

          # Nix store files are read-only (0444).
          # Make the new local copy writable so you can actually edit it.
          chmod +w "$symlink"

          echo "✓ Flattened: $name"
      done

      echo "--------------------------------------------------------"
      echo "Done. To restore: systemctl restart home-manager-$(whoami).service"
    '';
  };

  paperless-mcp = pkgs.callPackage ./paperless-mcp { };

  rge = pkgs.writeShellApplication {
    name = "rge";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      ripgrep
    ];
    text = ''rg -LSP "$1" | fzf | cut -d: -f1 | xargs "$EDITOR"'';
  };

  rgsti = pkgs.writeShellApplication {
    name = "rgsti";
    runtimeInputs = with pkgs; [
      coreutils
      fzf
      ripgrep
    ];
    text = ''
      rg -LSP "$1" \
        | fzf --delimiter=: \
          --with-nth=1.. \
          --preview 'echo "=== SELECTED ==="; printf "%s\n" {+}' \
          --preview-label 'Selection' \
        | cut -d: -f1 \
        | sort -u \
        | while IFS= read -r file; do
            echo "=== $file ==="
            cat "$file"
          done \
      | "$EDITOR"
    '';
  };

  fdsti = pkgs.writeShellApplication {
    name = "fdsti";
    runtimeInputs = with pkgs; [
      coreutils
      fd
      fzf
    ];
    text = ''
      fd -u . ./ '.*' \
        | fzf --delimiter=: \
          --with-nth=1.. \
          --preview 'echo "=== SELECTED ==="; printf "%s\n" {+}' \
          --preview-label 'Selection' \
        | cut -d: -f1 \
        | sort -u \
        | while IFS= read -r file; do
            echo "=== $file ==="
            cat "$file"
          done \
      | "$EDITOR"
    '';
  };

  export-gpg-keys = pkgs.writeShellApplication {
    name = "export-gpg-keys";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnupg
      zoxide
    ];
    text = ''
      declare OUTPUT_DIR PRIMARY_KEY_ID EMAIL GPG_UID
      declare -a KEYS=(
        "primary:75DB252683B07650"
        "auth:30973F79B17F9ED3"
        "enc:940B76AB99D87247"
        "sig:FC4881A7361DF34E"
      )

      if [[ $# -gt 0 ]]; then
        OUTPUT_DIR="$1"
        shift
      else
        OUTPUT_DIR=$(
          zoxide query --list Secrets | head -n1 \
          || echo "$HOME/Secrets"
        )
      fi

      # Remove trailing slash unless it's just root "/"
      OUTPUT_DIR=''${OUTPUT_DIR%/}

      mkdir -p "$OUTPUT_DIR" || {
        echo "Failed to create directory: $OUTPUT_DIR" >&2
        exit 1
      }

      PRIMARY_KEY_ID=''${KEYS[1]##*:}

      GPG_UID=$(gpg --list-secret-keys --with-colons "$PRIMARY_KEY_ID" | awk -F ':' '$1=="uid" {print $10; exit}')
      EMAIL=''${GPG_UID##*<}
      EMAIL=''${EMAIL%%>*}

      if [[ -z "$EMAIL" || "$EMAIL" == "$GPG_UID" ]]; then
        echo "Could not determine email from GPG UID for key $PRIMARY_KEY_ID" >&2
        exit 1
      fi

      success=0
      declare pair key key_id filename
      for pair in "''${KEYS[@]}"; do
        key=''${pair%%:*}
        key_id=''${pair##*:}
        filename="$OUTPUT_DIR/$EMAIL.$key.priv.asc"

        if gpg --armor --export-secret-keys "$key_id!" > "$filename"; then
          echo "✓ Exported $key key ($key_id) to $filename"
          # Using `set -e` in a script prevents ((var++)) increment in bash
          # Ref: https://stackoverflow.com/a/49072797/26004653
          ((++success))
        else
          echo "✗ Failed to export $key key ($key_id)" >&2
        fi
      done

      echo "Exported $success/''${#KEYS[@]} keys to $OUTPUT_DIR"
    '';
  };
}
