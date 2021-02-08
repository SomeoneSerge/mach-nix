{

  description = "Create highly reproducible python environments";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.pypi-deps-db = {
    url = "github:DavHau/pypi-deps-db";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
  let systemDependent =
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mach-nix-default = import ./default.nix {inherit pkgs;};
      in rec
      {
        devShell = import ./shell.nix {
          inherit pkgs;
        };
        packages = flake-utils.lib.flattenTree rec {
          inherit (mach-nix-default)
            mach-nix
            pythonWith
            shellWith
            dockerImageWith;
          "with" = pythonWith;
        };

        defaultPackage = packages.mach-nix;

        apps.mach-nix = flake-utils.lib.mkApp { drv = packages.mach-nix.mach-nix; };
        defaultApp = { type = "app"; program = "${defaultPackage}/bin/mach-nix"; };

        lib = {
          inherit (mach-nix-default)
          mkPython
          mkPythonShell
          mkDockerImage
          mkOverlay
          mkNixpkgs
          mkPythonOverrides

          buildPythonPackage
          buildPythonApplication
          fetchPypiSdist
          fetchPypiWheel
          ;
        };
      }
  );
  in systemDependent // {
    lib = systemDependent.lib.x86_64-linux; /* FIXME: */
  };
}
