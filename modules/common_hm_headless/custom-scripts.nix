{ pkgs, ... }:
{
  home.file =
    let
      local_bin = ".local/bin";
    in
    {
      # Replace symlinks to from `/nix/store` to editable files for debugging
      "${local_bin}/flatten-symlinks" = {
        executable = true;
        source = pkgs.writeShellScript "flatten-symlinks" ''
          set -euo pipefail

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

      # Search and open editor
      "${local_bin}/rge" = {
        executable = true;
        source = pkgs.writeShellScript "rge" ''
          set -euo pipefail
          rg -LSP "$1" | fzf | cut -d: -f1 | xargs $EDITOR
        '';
      };

      # Search and stich files
      "${local_bin}/rgsti" = {
        executable = true;
        source = pkgs.writeShellScript "rgsti" ''
          set -euo pipefail
          rg -LSP "$1" \
            | fzf --delimiter=: \
              --with-nth=1.. \
              --preview 'echo "=== SELECTED ==="; printf "%s\n" {+}' \
              --preview-label 'Selection' \
            | cut -d: -f1 \
            | sort -u \
            | while IFS= read file; do
                echo "=== $file ==="
                cat "$file"
              done \
          | $EDITOR
        '';
      };

      "${local_bin}/fdsti" = {
        executable = true;
        source = pkgs.writeShellScript "fdsti" ''
          set -euo pipefail
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
          | $EDITOR
        '';
      };

      # Export GPG primary key and subkeys to a specified (or default) directory
      "${local_bin}/export-gpg-keys" = {
        executable = true;
        source = pkgs.writeShellScript "export-gpg-keys" ''
          set -euo pipefail

          local OUTPUT_DIR PRIMARY_KEY_ID EMAIL GPG_UID
          local -a KEYS=(
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
            return 1
          }

          PRIMARY_KEY_ID=''${KEYS[1]##*:}

          GPG_UID=$(gpg --list-secret-keys --with-colons "$PRIMARY_KEY_ID" | awk -F ':' '$1=="uid" {print $10; exit}')
          EMAIL=''${GPG_UID##*<}
          EMAIL=''${EMAIL%%>*}

          if [[ -z "$EMAIL" || "$EMAIL" == "$GPG_UID" ]]; then
            echo "Could not determine email from GPG UID for key $PRIMARY_KEY_ID" >&2
            return 1
          fi

          local success=0
          local pair key key_id filename
          for pair in ''${KEYS[@]}; do
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
    };

}
