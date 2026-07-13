# NixOS Configurations Flake

Personal NixOS and nix-darwin system configurations.

## Notice: Something that makes this nixos-config a little different

- In order to make NS subdomain declaration molecular. I need a global option that shares across machines. e.g., for [`modules/variables/host-addrs.nix`](./modules/variables/host-addrs.nix), the implementation [`const/networking.nix`](./const/networking.nix) utilize `lib.evalModules` to merge all options `config.vars.hostAddrs.*` under `nixosConfigurations.*` (and `darwinConfigurations.*`)

## Installation

1. **Review and customize disko configuration:**

```bash
hx machines/<system>/<hostname>/disko-config.nix
```

2. **Generate & Modify `hardware-configuration.nix`**

```bash
sudo nixos-generate-config --show-hardware-config
```

3. **Install NixOS:**

```bash
sudo nixos-install --flake .#<hostname>
```

4. **Move critical files to `/mnt/persistent`:**

```bash
sudo mv /mnt/etc/ssh/* /mnt/persistent/etc/ssh/
sudo mv /mnt/etc/machine-id /mnt/persistent/etc/machine-id
sudo mv /mnt/var/l{ib,og} /mnt/persistent/var/
```

Or use `nixos-anywhere` for unattended installation (example using `Proteus-NixOS-0`):

```bash
IP=11.4.51.4
Machine=Proteus-NixOS-0
nix run nixpkgs#nixos-anywhere -- -f .#$Machine --phases kexec proteus@$IP \
  --kexec https://gh-proxy.org/https://github.com/nix-community/nixos-images/releases/download/nixos-25.05/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
nix run nixpkgs#nixos-anywhere -- -f .#$Machine --phases disko --disko-mode format root@$IP
nix run nixpkgs#nixos-anywhere -- -f .#$Machine --phases disko --disko-mode mount root@$IP
nix run nixpkgs#nixos-anywhere -- -f .#$Machine --phases install root@$IP
# Check everything ok, then move critical files to `/mnt/persistent`, see above
# Finally reboot
nix run nixpkgs#nixos-anywhere -- -f .#$Machine --phases reboot root@$IP
# After reboot, enroll the tpm key
systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-partlabel/disk-main-root
```

_If meet error when formatting, try `sgdisk --zap-all /dev/<disk>`; For luks wipe the fs header `sudo wipefs -a /dev/disk/by-partlabel/xxx`_

## Tips

TODO: move to my personal notebook

### Updating the system

```bash
nix flake update
just <host nickname>
```

### Remote deployment

```bash
deploy [-s] --targets \
  /home/proteus/nixos_configs_flake#Proteus-NUC \
  /home/proteus/nixos_configs_flake#Proteus-Desktop \
  /home/proteus/nixos_configs_flake#Proteus-NixOS-{0..5} \
-- --show-trace --verbose
```

### Quick Debug

Use the first machine as-is:

```bash
nix-repl> (builtins.head _DEBUG.nixos_systems.x86_64-linux._DEBUG.machines)._DEBUG.const.networking.hostAddrs.Proteus-NUC
```

Or find the specific machine:

```bash
nix-repl> (builtins.elemAt _DEBUG.nixos_systems.x86_64-linux._DEBUG.machines 1)._DEBUG.name
"Proteus-NUC"
```

## AI Disclosure

Current AIGC has limitations: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing#Language_and_grammar

Currently I don't run vibe coding directly. I actively use AI chat to do research and always recheck.

Through not frequently as now, I may:

- use Claude Sonnet 4.6 to assist in
  - Git messages
- use Gemini 3.1 Pro to assist in
  - Generate prototype
  - Debugging

## References

- [NixOS](https://nixos.org/)
- [ZFS - Official NixOS Wiki](https://wiki.nixos.org/wiki/ZFS)
- [Disko](https://github.com/nix-community/disko)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [impermanence](https://github.com/nix-community/impermanence)
- [deploy-rs](https://github.com/serokell/deploy-rs)
- [sing-box](https://github.com/SagerNet/sing-box)
- [Graham Christensen's "Erase Your Darlings"](https://grahamc.com/blog/erase-your-darlings)

## Acknowledgments

Inspired by:

- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)

ASCII Logo:

```plaintext
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣦⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⡿⢀⠹⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣧⡀⣠⣿⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠈⠇⣼⣆⢻⡇⢬⡀⠀⠀⠀⠀⠀⠀⠀⠀⠻⠂⣼⡆⢿⣿⣷⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⡀⢺⠷⢀⣀⠛⡏⣠⣇⠘⢻⡁⣀⣀⣀⠀⣴⡶⢿⣿⠿⣶⣦⣄⠳⣶⣶⣮⣭⡛⠿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣠⣷⣿⣿⢁⡇⣼⣾⣿⠀⡇⢹⣿⣿⡆⢳⡘⣿⣿⠀⣿⡾⢛⢉⣤⣤⣤⣍⡓⢌⠻⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⢠⣆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⢸⡇⣿⣿⣿⠀⣧⢸⣿⣿⣷⢸⡇⢹⣿⣧⡙⣨⡹⣿⣿⣿⣿⣯⣝⢮⢳⡽⣿⣿⣿⡿⠄⠀⠀⠀⠀⣰⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠘⣧⡈⠉⠉⡁⣿⢈⣉⠉⢁⣼⠇⠈⠉⠉⢱⡿⢳⣿⢟⣵⣶⣶⡹⢸⠀⣷⣾⣿⢁⣶⣶⣶⣶⠃⣴⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠷⢶⣶⣿⣶⠶⢾⠛⠁⡀⠀⣰⣾⣮⠡⣇⣿⣿⣿⠿⢧⡞⢸⣿⣿⣿⣜⠻⠿⠟⢋⣼⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣷⣶⢸⡇⣿⠏⠀⠀⠉⠲⣄⢴⣶⣶⣎⠋⣿⣿⡇⢡⣿⡇⣿⣿⣿⣿⣿⣿⠇⢀⣾⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣸⡇⠋⠀⠀⠀⠀⠀⠈⠳⣿⣷⣼⣿⣦⣭⡛⢛⢿⢸⣿⣿⣿⡿⢟⡉⢠⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣴⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⡇⣇⠀⠀⠀⠀⠀⠀⠀⣸⢠⣭⣉⠉⣽⠎⢔⣢⡾⢸⣿⡇⠁⢶⠏⣰⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣶⣶⣆⠀
⢼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⣥⢋⣤⡀⠀⠀⠀⠀⠀⡻⠈⠻⠟⣃⣠⡖⠁⠀⠀⢸⣿⣇⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇
⠀⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⢚⢠⢘⣿⣦⣀⣀⣤⣶⣯⣿⣷⣾⣿⣿⣿⣷⣄⠀⢸⣿⣿⠆⢸⣿⣿⣿⣿⣿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠏⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⠏⣰⣿⡆⢵⡄⢻⣿⣿⣿⣿⣳⣿⣿⣿⣿⡏⣟⢿⣿⣿⣷⣄⠀⢀⣾⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⠋⢴⣿⣿⡇⢸⡇⠌⠻⣿⠿⢳⣿⣿⣿⣿⣿⣷⢻⣦⡝⠻⣿⣿⡆⢻⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⡿⠃⠀⠀⢻⣿⣇⢸⡇⢸⢂⠀⠀⣾⣿⣿⣿⣿⣿⣿⣟⣿⣷⡝⣾⠿⣣⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠱⣻⢸⣧⢸⣿⣦⠀⢿⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣆⢤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⣤⡄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠙⠀⣿⠘⣿⡿⢃⣜⣿⣿⣿⣿⣿⣿⡿⣹⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠹⠏⠀⠀⠀⠀⠀⠀⠀⠀⣰⠀⣿⠀⣿⠁⣿⣿⣮⡻⣿⣿⡿⣫⣾⣿⣿⣿⡿⣾⡿⢟⣛⣿⣭⣽⣿⡻⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣽⡇⣿⡄⠋⡁⠬⢝⣛⣻⣳⣯⢱⣿⣿⣿⣿⣏⢾⣦⣝⣻⣿⣿⣿⡯⠛⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⣿⡇⠻⠃⠈⠔⠚⣈⣋⣭⣅⠀⣀⠘⠛⠿⠿⠿⠀⠰⣶⣶⣶⣾⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⡯⠃⠀⠩⣿⣿⣿⣿⣷⢬⠀⠊⠁⠰⠟⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠙⡿⣿⣿⣿⣷⣧⡀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣽⣿⣿⠟⠀⠀⠀⠀⠀⠀⠘⠿⢿⣿⣿⣿⡵⡀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
```

- [darwin-nix](https://github.com/nix-darwin/nix-darwin)
