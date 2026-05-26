#!/usr/bin/env bash
set -eufo pipefail

# Function: nixos-switch
# Args:
#   $1: name (string)
#   $2: mode (string)
nixos-switch() {
  local name="$1"
  local mode="$2"
  if [[ $mode == "debug" ]]; then
    # show details via nix-output-monitor
    nom build ".#nixosConfigurations.$name.config.system.build.toplevel" --show-trace --verbose
    nixos-rebuild switch --sudo --flake ".#$name" --show-trace --verbose
  else
    nixos-rebuild switch --sudo --flake ".#$name"
  fi
}

# Function: darwin-build
# Args:
#   $1: name (string)
#   $2: mode (string) - e.g., "debug"
darwin-build() {
  local name="$1"
  local mode="$2"
  local target=".#darwinConfigurations.$name.system"

  if [[ $mode == "debug" ]]; then
    nom build "$target" --extra-experimental-features "nix-command flakes" --show-trace --verbose
  else
    nix build "$target" --extra-experimental-features "nix-command flakes"
  fi
}

# Function: darwin-switch
# Args:
#   $1: name (string)
#   $2: mode (string)
darwin-switch() {
  local name="$1"
  local mode="$2"
  local flake_path=".#$name"

  if [[ $mode == "debug" ]]; then
    sudo darwin-rebuild switch --flake "$flake_path" --show-trace --verbose
  else
    sudo darwin-rebuild switch --flake "$flake_path"
  fi
}

darwin-rollback() {
  darwin-rebuild --rollback
}

# Function: upload-vm
# Args:
#   $1: name (string)
#   $2: mode (string)
upload-vm() {
  local name="$1"
  local mode="$2"
  local target=".#$name"
  if [[ $mode == "debug" ]]; then
    nom build $target --show-trace --verbose
  else
    nix build $target
  fi
  local remote="proteus@proteus-desktop:/mnt/storage/data/vms/kubevirt-$name.qcow2"
  rsync -acvzL --progress result "$remote"
}
