# TODO: Drop once https://github.com/NixOS/nixpkgs/pull/585411 lands
# Ref: https://github.com/NixOS/nixpkgs/issues/585072)
_: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  localsend = prev.localsend.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ prev.zlib ];
  });
}
