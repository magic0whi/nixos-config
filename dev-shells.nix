_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt-rs
          prettier
        ];
        name = "nixos-config";
      };
    };
}
