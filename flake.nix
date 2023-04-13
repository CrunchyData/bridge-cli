{
  description = "CrunchyBridge CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-crunchy.url = "github:crunchydata/nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-crunchy, flake-utils }:
    let
      systems = builtins.map (a: a.system) (builtins.catAttrs "crystal" (builtins.attrValues nixpkgs-crunchy.outputs.packages));
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crystal-pkgs = nixpkgs-crunchy.packages.${system};

        crystal = crystal-pkgs.crystal;
        crystalWrapped = crystal-pkgs.extraWrapped.override {
          buildInputs = [ pkgs.libssh2 ];
        };

        c2n = pkgs.crystal2nix.override { inherit crystal; };
      in
      {
        packages.default = crystalWrapped.mkPkg {
          inherit self;
          shards = crystal-pkgs.shards;
          src = ./.;
          doCheck = false;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ crystalWrapped c2n ];
        };

      }
    );
}
