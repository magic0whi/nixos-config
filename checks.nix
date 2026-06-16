{
  perSystem =
    { pkgs, lib, ... }:
    {
      checks = lib.mkMerge [
        {
          mylib =
            let
              result = import ./libs/tests.nix pkgs;
            in
            if result == [ ] then
              pkgs.runCommand "lib-tests-passed" { } ''
                echo "All custom library unit tests passed on ${pkgs.stdenv.hostPlatform.system}!"
                touch $out
              ''
            else
              throw ''
                Library unit tests failed on ${pkgs.stdenv.hostPlatform.system}!
                ${builtins.toJSON result}
              '';
        }
        # VM tests
        (lib.mkIf (!pkgs.stdenv.isDarwin) (import ./tests { inherit pkgs; }))
      ];
    };
}
