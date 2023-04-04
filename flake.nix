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
        crystal = nixpkgs-crystal.packages.${system}.crystal; #_release;

        c2n = pkgs.crystal2nix.override { inherit crystal; };
        shardValue = key: builtins.head (builtins.match (".*"+key+": ([-a-zA-Z0-9\.]+).*") (builtins.readFile ./shard.yml));
      in
      {

        packages.default = crystal.buildCrystalPackage {
          pname = shardValue "name";
          version = shardValue "version";
          gitSha = self.shortRev or "dirty";
          src = ./.;
          format = "shards";
          lockFile = ./shard.lock;
          shardsFile = ./shards.nix;
          doCheck = false;
          buildInputs = with pkgs; [ libssh2 ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ crystal pkgs.libssh2 c2n ];
        };

      }
    );
}
