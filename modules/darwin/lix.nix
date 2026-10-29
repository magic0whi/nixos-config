{ lib, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (_: prev: {
      lix = prev.lix.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          # 1. sandbox is broken on macOS 27 due to change in accepted errno values for deny
          #    Ref: https://git.lix.systems/lix-project/lix/issues/1308
          substituteInPlace lix/libstore/platform/sandbox-defaults.sb \
            --replace-fail '(deny file-write-mode (with errno ENOTSUP)' '(allow file-write-mode'
          # 2. In the darwin sandbox, `> /dev/full` fails in bash itself with "Permission denied" instead of
          # "Operation not permitted", which `test_bad_fd` doesn't accept.
          #    Ref: https://git.lix.systems/lix-project/lix/issues/1310
          substituteInPlace tests/functional2/store/test_export.py \
            --replace-fail \
              'or "Operation not permitted" in res.stderr_plain' \
              'or "Operation not permitted" in res.stderr_plain or "/dev/full: Permission denied" in res.stderr_plain'
        '';
      });
    })
  ];
}
