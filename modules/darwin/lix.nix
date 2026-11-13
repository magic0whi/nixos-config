{ lib, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (_: prev: {
      lix = prev.lix.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # libc++ marks `std::optional::operator*` as [[nodiscard]], which trips
          # `-Werror=unused-result` on the bare `*backoff.next();` statements.
          # TODO: Drop once the pinned Lix includes this commit (the patch will then fail to apply)
          # Ref: https://git.lix.systems/lix-project/lix/commit/a16e8511de98ad1b4d7ef73afd97d995bc32ea28
          (prev.fetchpatch {
            url = "https://git.lix.systems/lix-project/lix/commit/a16e8511de98ad1b4d7ef73afd97d995bc32ea28.patch";
            hash = "sha256-Nq4ShQ/RwgmLNBHP+0SGVqxNY8BlcJOu425TqjLDIX8=";
          })
        ];
        postPatch = (old.postPatch or "") + ''
          # `> /dev/full` fails in bash itself with "Permission denied" instead of
          # "Operation not permitted", which `test_bad_fd` doesn't accept.
          # Ref: https://git.lix.systems/lix-project/lix/issues/1310
          substituteInPlace tests/functional2/store/test_export.py \
            --replace-fail \
              'or "Operation not permitted" in res.stderr_plain' \
              'or "Operation not permitted" in res.stderr_plain or "/dev/full: Permission denied" in res.stderr_plain'
        '';
      });
    })
  ];
}
