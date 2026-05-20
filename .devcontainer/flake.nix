{
  description = "Typst runtime closure for minimal Docker image";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # List of systems we support
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper: for each system, build an attrset of packages
      perSystem = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          typstRuntime = pkgs.buildEnv {
            name = "typst-runtime";
            paths = with pkgs; [
              bashInteractive
              busybox
              coreutils
              typst
              fontconfig
              dejavu_fonts
              stdenv.cc
            ];
            pathsToLink = [ "/bin" "/share" ];
          };
        in {
          typst-runtime = typstRuntime;
        });
    in {
      # Expose them under the standard flake schema:
      # packages.<system>.typst-runtime
      packages = perSystem;
    };
}