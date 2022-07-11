{
  description = "An IPLD package for Lean 4";

  inputs = {
    lean = {
      url = github:leanprover/lean4;
    };
    LSpec = {
      # url = github:yatima-inc/LSpec;
      url = github:anderssorby/LSpec/acs/add-flake;
      inputs.lean.follows = "lean";
    };
    YatimaStdLib = {
      # url = github:yatima-inc/YatimaStdLib.lean;
      url = github:anderssorby/YatimaStdLib.lean/acs/add-flake;
      inputs.lean.follows = "lean";
    };
    nixpkgs.url = github:nixos/nixpkgs/nixos-22.05;
    utils = {
      url = github:yatima-inc/nix-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, lean, utils, nixpkgs, ... } @ inputs:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      inherit (utils) lib;
    in
    lib.eachSystem supportedSystems (system:
      let
        leanPkgs = lean.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        name = "Ipld";  # must match the name of the top-level .lean file
        project = leanPkgs.buildLeanPackage {
          inherit name;
          deps = with inputs; [
            LSpec.project.${system}
            YatimaStdLib.project.${system}
          ];
          # Where the lean files are located
          src = ./.;
        };
        test = leanPkgs.buildLeanPackage {
          name = "Tests";
          deps = [ project ];
          # Where the lean files are located
          src = ./.;
        };
      in
      {
        inherit project test;
        packages = project // {
          ${name} = project.executable;
          test = test.executable;
        };

        checks.test = test.executable;

        defaultPackage = self.packages.${system}.${name};
        devShell = pkgs.mkShell {
          inputsFrom = [ project.executable ];
          buildInputs = with pkgs; [
            leanPkgs.lean-dev
          ];
          LEAN_PATH = "./src:./test";
          LEAN_SRC_PATH = "./src:./test";
        };
      });
}