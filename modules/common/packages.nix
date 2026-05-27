# These a packages available both on Linux & Darwin
{ lib, pkgs, ... }:
{
  environment.systemPackages =
    (with pkgs; [
      # Misc
      findutils
      tree
      gnutar
      gnugrep # GNU grep, provides `grep`/`egrep`/`fgrep`
      curl

      # Archives
      xz
      zstd
      p7zip

      # Networking Tools
      mtr # A network diagnostic tool
      iperf3
      # ldns # replacement of `dig`, it provide the command `drill`
      # wget
      # socat # replacement of openbsd-netcat
      # nmap # A utility for network discovery and security auditing
      # ipcalc # it is a calculator for the IPv4/v6 addresses

      # BPF/eBPF Related Tools
      # bpftop # monitor BPF programs
      # bpfmon # BPF based visual packet rate monitor

      # System Monitoring
      # iftop
      # sysbench

      # System Tools
      pciutils # lspci
      usbutils # lsusb
    ])
    ++ lib.optionals pkgs.stdenv.isLinux (
      with pkgs;
      [
        # Misc
        file
        # which # Zsh built-in it

        # Archives
        zip
        unzipNLS

        # Text Processing, ref: https://github.com/learnbyexample/Command-line-text-processing
        gnused # GNU sed, very powerful(mainly for replacing text in files)
        gawk # GNU awk, a pattern scanning and processing language
        jq # A lightweight and flexible command-line JSON processor

        # Networking Tools
        # dnsutils # `dig` + `nslookup`

        # System Call Monitoring
        # tcpdump # network sniffer
        # lsof # list open files
      ]
    );
}
