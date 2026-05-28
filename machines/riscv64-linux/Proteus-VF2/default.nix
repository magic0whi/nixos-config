{
  inputs,
  lib,
  mylib,
  myvars,
  ...
}:
let
  name = baseNameOf ./.;
  nixpkgs_modules = map mylib.relativeToRoot [
    "modules/secrets/common.nix"
    "modules/common"
    "modules/nixos_headless/impermanence.nix"
    "modules/nixos_headless/misc.nix"
    "modules/nixos_headless/packages.nix"
    "modules/nixos_gui/kmscon.nix"
  ];
  hm_modules = map mylib.relativeToRoot [
    "modules/common_hm_headless/git.nix"
    "modules/common_hm_headless/helix.nix"
    "modules/common_hm_headless/packages.nix"
    "modules/common_hm_headless/shell.nix"
    "modules/common_hm_headless/misc.nix"
    "modules/nixos_hm_headless/shell.nix"
  ];
  nixos_system = lib.nixosSystem (
    mylib.genOsConfiguration {
      inherit
        name
        mylib
        myvars
        nixpkgs_modules
        hm_modules
        ;
      system = "x86_64-linux"; # Cross-compile
      machine_path = ./.;
    }
  );
  # TODO: WIP, broken
  nixos_sd_image =
    (inputs.nixpkgs.lib.nixosSystem (
      mylib.genOsConfiguration {
        inherit
          name
          mylib
          myvars
          hm_modules
          ;
        machine_path = ./.;
        nixpkgs_modules = nixpkgs_modules ++ [
          {
            imports = [ "${inputs.nixos-hardware}/starfive/visionfive/v2/sd-image-installer.nix" ];
            sdImage.compressImage = false;
            # Cross-compile, either
            nixpkgs.buildPlatform = "x86_64-linux";
            # Or add `boot.binfmt.emulatedSystems = ["riscv64-linux"];` to your NixOS configurations
            disko.enableConfig = false; # nixpkgs' sd-image.nix use its built-in ext4
            nixpkgs.overlays = [
              (final: prev: {
                coreutils = prev.coreutils.overrideAttrs (prev: {
                  postPatch = prev.postPatch + ''
                    # Fails when build through cross compile
                    echo "int main() { return 77; }" > "gnulib-tests/test-free.c"
                    sed '2i echo Skipping split line-bytes test && exit 77' -i ./tests/split/line-bytes.sh
                  '';
                });
                findutils = prev.findutils.overrideAttrs (prev: {
                  postPatch = prev.postPatch + ''
                    # Fails when build through cross compile
                    echo "int main() { return 77; }" > "gnulib-tests/test-free.c"
                  '';
                });
                openexr = prev.openexr.overrideAttrs (_: {
                  doCheck = false;
                });
                # perl540Packages = prev.perl540Packages.overrideScope (_: perl_prev: {
                # });
                perlPackages = prev.perlPackages.overrideScope (
                  _: perl_prev: {
                    Test2Harness = perl_prev.Test2Harness.overrideAttrs (_: {
                      doCheck = false;
                    });
                    MIMECharset = prev.perlPackages.MIMECharset.overrideAttrs (prev: {
                      # 1. Force removing the bundled inc/ directory so it uses the system Module::Install
                      # This bypasses the bundled Makefiles that trigger the Fcntl error.
                      preConfigure = "rm -rf inc";

                      # 2. Ensure Module::Install is available as a build dependency
                      nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ final.perlPackages.ModuleInstall ];
                    });
                    SGMLSpm = prev.perlPackages.SGMLSpm.overrideAttrs (prev: {
                      nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ final.perlPackages.ModuleBuild ];
                    });
                  }
                );
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (_: python_prev: {
                    fs = python_prev.fs.override { pytestCheckHook = null; };
                    hypothesis = python_prev.hypothesis.override { pytestCheckHook = null; };
                  })
                ];
                git = prev.git.overrideAttrs (prev: {
                  preInstallCheck = prev.preInstallCheck + ''
                    # Fails on cross-compile on riscv64-linux
                    disable_test t0050-filesystem
                    disable_test t4200-rerere
                  '';
                });
                rsync = prev.rsync.overrideAttrs (prev: {
                  passthru = prev.passthru // {
                    tests = { };
                  };
                });
                elfutils = prev.elfutils.overrideAttrs (prev: {
                  postPatch = prev.postPatch + ''
                    # Fails when build through cross-compile
                    sed '2i echo Skipping run strip reloc ko && exit 77' -i ./tests/run-strip-reloc-ko.sh
                  '';
                });
                yascreen = prev.yascreen.overrideAttrs (prev: {
                  postPatch = (prev.postPatch or "") + ''
                    # Replace 'install -Ds' with 'install -D' (no strip)
                    substituteInPlace Makefile.main \
                      --replace '$(INSTALL) -Ds' '$(INSTALL) -D'
                  '';
                  # Force the build to use the correctly prefixed AR tool from the stdenv
                  makeFlags = (prev.makeFlags or [ ]) ++ [ "AR=${final.stdenv.cc.targetPrefix}gcc-ar" ];
                });
                adcli = prev.adcli.overrideAttrs (prev: {
                  # Force the check to 'no' (not present) to bypass the error
                  # Or 'yes' if you are somehow providing it in the sysroot (unlikely for cross)
                  configureFlags = (prev.configureFlags or [ ]) ++ [ "ac_cv_file__usr_share_selinux_devel_Makefile=no" ];
                });
              })
            ];
          }
        ];
      }
    )).config.system.build.images.sd-card;
  # })); # For debug
in
{
  _DEBUG = {
    inherit
      name
      nixpkgs_modules
      hm_modules
      myvars
      mylib
      nixos_system
      ;
  };
  nixos_configurations.${name} = nixos_system;
  packages.${name} = nixos_sd_image; # Generate iso image
  deploy-rs_node.${name} = mylib.genDeployNode myvars.networking.hosts_addr.${name} nixos_system;
}
