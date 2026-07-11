# just is a command runner, Justfile is very similar to Makefile, but simpler.
set shell := ["zsh", "-c"] # Use zsh for shell commands

utils := absolute_path("utils.sh")

##############################################################
#
# Common commands(suitable for all machines)
#
##############################################################

# List all the just commands
default:
    @just --list

# Run eval tests on machine
[group('nix')]
[linux]
test name:
    nom build --show-trace --verbose -o /tmp/result .#nixosConfigurations.{{ name }}.config.system.build.toplevel

[group('nix')]
[macos]
test name:
    nom build --show-trace --verbose -o /tmp/result .#darwinConfigurations.{{ name }}.config.system.build.toplevel

# Update all the flake inputs
[group('nix')]
up:
    nix flake update

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
    nix flake update {{ input }}

# List all generations of the system profile
[group('nix')]
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
    nix repl -f flake:nixpkgs

# Remove all generations older than 7 days
# On darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
    # Garbage collect all unused nix store entries (system-wide)
    sudo nix-collect-garbage --delete-older-than 7d
    # Garbage collect all unused nix store entries (for the user - home-manager)
    # https://github.com/NixOS/nix/issues/8508
    nix-collect-garbage --delete-older-than 7d

# Enter a shell session which has all the necessary tools for this flake
[group('nix')]
shell:
    nix develop .# -c zsh

# Format the nix files in this repo
[group('nix')]
fmt:
    nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
    ls -al /nix/var/nix/gcroots/auto/

# Run all flake checks (including your new VM tests)
[group('nix')]
check:
    nix flake check --keep-going --show-trace --verbose

# Run a specific VM test
[group('nix')]
test-vm test_name:
    nom build .#checks.x86_64-linux.{{ test_name }} --show-trace --verbose

# Run a specific VM test interactively (great for debugging)
[group('nix')]
test-vm-i test_name:
    nix run .#checks.x86_64-linux.{{ test_name }}.driverInteractive --show-trace --verbose

# Nix Store can contains corrupted entries if the nix store object has been modified unexpectedly. This command will
# verify all the store entries, and we need to fix the corrupted entries manually via
# `sudo nix store delete <store-path-1> <store-path-2> ...`
# Verify all the store entries
[group('nix')]
verify-store:
    nix store verify --all

# Repair Nix Store Objects
[group('nix')]
repair-store *paths:
    nix store repair {{ paths }}

##############################################################
#
# NixOS Desktop related commands
#
##############################################################

[group('desktop')]
[linux]
proteus-nuc mode="default":
    #!/usr/bin/env bash
    . {{ utils }}
    nixos-switch Proteus-NUC {{ mode }}

##############################################################
#
# Darwin related commands
#
##############################################################

[group('desktop')]
[macos]
darwin-rollback:
    #!/usr/bin/env bash
    . {{ utils }} *;
    darwin-rollback

[group('desktop')]
[macos]
proteus-mbp mode="default":
    #!/usr/bin/env bash
    . {{ utils }}
    darwin-build "Proteus-MBP14M4P" {{ mode }} && darwin-switch "Proteus-MBP14M4P" {{ mode }}

# Reset launchpad to force it to reindex Applications
[group('desktop')]
[macos]
reset-launchpad:
    defaults write com.apple.dock ResetLaunchPad -bool true
    killall Dock

##############################################################
#
# Homelab - Kubevirt Cluster related commands
#
##############################################################

# Remote deployment via deploy-rs
[group('homelab')]
[linux]
deploy +names:
    #!/usr/bin/env bash
    targets=""
    for name in {{ names }}; do
        targets="$targets .#$name"
    done
    deploy --skip-checks --auto-rollback false --magic-rollback false --targets $targets -- --verbose --show-trace

# Local switch
[group('homelab')]
[linux]
local name mode="default":
    #!/usr/bin/env bash
    . {{ utils }}
    nixos-switch {{ name }} {{ mode }}

# TODO
# Build and upload a vm image
[group('homelab')]
[linux]
upload-vm name mode="default":
    #!/usr/bin/env nu
    use {{ utils }} *;
    upload-vm {{ name }} {{ mode }}

# TODO: Learn KubeVirt
# Deploy all the nodes
[group('homelab')]
[linux]
all:
    deploy --targets \
    .#Proteus-NUC \
    .#Proteus-Desktop \
    .#Proteus-NixOS-{0..5} \
    -- --show-trace --verbose

[group('homelab')]
[linux]
nodes:
    deploy --skip-checks --targets .#Proteus-NixOS-{0..5} -- --show-trace --verbose

[group('homelab')]
[linux]
proteus-desktop:
    deploy --skip-checks .#Proteus-Desktop -- --verbose --show-trace

############################################################################
#
# Commands for other Virtual Machines
#
############################################################################

# Build and upload a vm image
[group('homelab')]
[linux]
upload-idols mode="default":
    #!/usr/bin/env nu
    use {{ utils }} *;
    upload-vm aquamarine {{ mode }}
    upload-vm ruby {{ mode }}
    upload-vm kana {{ mode }}

############################################################################
#
# Kubernetes related commands
#
############################################################################

# Build and upload a vm image
[group('homelab')]
[linux]
upload-k3s-prod mode="default":
    #!/usr/bin/env nu
    use {{ utils }} *;
    upload-vm k3s-prod-1-master-1 {{ mode }};
    upload-vm k3s-prod-1-master-2 {{ mode }};
    upload-vm k3s-prod-1-master-3 {{ mode }};
    upload-vm k3s-prod-1-worker-1 {{ mode }};
    upload-vm k3s-prod-1-worker-2 {{ mode }};
    upload-vm k3s-prod-1-worker-3 {{ mode }};

[group('homelab')]
[linux]
upload-k3s-test mode="default":
    #!/usr/bin/env nu
    use {{ utils }} *;
    upload-vm k3s-test-1-master-1 {{ mode }};
    upload-vm k3s-test-1-master-2 {{ mode }};
    upload-vm k3s-test-1-master-3 {{ mode }};

[group('homelab')]
[linux]
k3s-prod:
    colmena apply --on '@k3s-prod-*' --verbose --show-trace

[group('homelab')]
[linux]
k3s-test:
    colmena apply --on '@k3s-test-*' --verbose --show-trace

# =================================================
# Emacs related commands
# =================================================

[group('emacs')]
emacs-test:
    doom clean
    doom sync

[group('emacs')]
emacs-purge:
    doom purge
    doom clean
    doom sync

[group('emacs')]
[linux]
emacs-reload:
    doom sync
    systemctl --user restart emacs.service
    systemctl --user status emacs.service

emacs-plist-path := "~/Library/LaunchAgents/org.nix-community.home.emacs.plist"

[group('emacs')]
[macos]
emacs-reload:
    doom sync
    launchctl unload {{ emacs-plist-path }}
    launchctl load {{ emacs-plist-path }}
    tail -f ~/Library/Logs/emacs-daemon.stderr.log

# =================================================
#
# Other useful commands
#
# =================================================
# TODO: Nushell-only commands
[group('common')]
path:
    $env.PATH | split row ":"

# TODO: Nushell-only commands
[group('common')]
trace-access app *args:
    strace -f -t -e trace=file {{ app }} {{ args }} | complete | $in.stderr | lines | find -v -r "(/nix/store|/newroot|/proc)" | parse --regex '"(/.+)"' | sort | uniq

[group('common')]
[linux]
penvof pid:
    sudo cat $"/proc/($pid)/environ" | tr '\0' '\n'

# Remove all reflog entries and prune unreachable objects
[group('git')]
ggc:
    git reflog expire --expire-unreachable=now --all
    git gc --prune=now

# Amend the last commit without changing the commit message
[group('git')]
gamend:
    git commit --amend -a --no-edit

# TODO
# Delete all failed pods
[group('k8s')]
del-failed:
    kubectl delete pod --all-namespaces --field-selector="status.phase==Failed"

[group('services')]
[linux]
list-inactive:
    systemctl list-units -all --state=inactive

[group('services')]
[linux]
list-failed:
    systemctl list-units -all --state=failed

[group('services')]
[linux]
list-systemd:
    systemctl list-units systemd-*
