{
  description = "CrunchyBridge CLI";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-crystal = {
      url = "github:will/nixpkgs-crystal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-crystal, flake-utils }:
    let
      systems = (builtins.attrNames nixpkgs-crystal.outputs.packages);
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crystal = nixpkgs-crystal.packages.${system}.crystal;
      in
      {

        devShells.default = pkgs.mkShell {
          buildInputs = [ crystal pkgs.libssh2 ];
        };

      }
    );
}
