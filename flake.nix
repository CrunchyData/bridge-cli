{
  description = "CrunchyBridge CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { nixpkgs, nix-filter, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      filterSrc = files: (nix-filter.lib { root = ./.; include = [ "src" "spec" ] ++ files; });

      perSystemOutputs = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          crystal = pkgs.crystal;

          check = pkgs.writeScriptBin "check" "nix build .#check --keep-going --print-build-logs";
          shardFiles = [ "shard.lock" "shards.nix" "shard.yml" ];
          src = filterSrc (shardFiles ++ [ "Readme" "Changelog" ]);
          specSrc = filterSrc shardFiles;
          lintSrc = filterSrc [ ".ameba.yml" ];

          # returns a function that can read a value for a key in shard.yml
          shardValue = src: key:
            let
              file = src + "/shard.yml";
              contents = builtins.readFile file;
              match = builtins.split (key + ": ([-a-zA-Z0-9\.]+).*\n") contents;
            in
            if builtins.length match == 3 then
              builtins.head (builtins.head (builtins.tail match))
            else
              builtins.traceVerbose "file ${file} doesn't have top-level key '${key}'" null;

          version = shardValue src "version";
        in
        rec {
          packages = {
            default = crystal.buildCrystalPackage {
              inherit src version;
              pname = "cb";
              format = "shards";
              shardsFile = ./shards.nix;
              buildInputs = [ pkgs.libssh2 ];
              doCheck = false;
            };
            check = pkgs.linkFarmFromDrvs "cb-all-checks" (builtins.attrValues checks);
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [ crystal2nix ameba shards libssh2 ]
              ++ [ crystal check ];
          };

          checks = {
            format = pkgs.stdenvNoCC.mkDerivation {
              name = "format";
              src = specSrc;
              installPhase = "mkdir $out && crystal tool format --check";
              nativeBuildInputs = [ crystal ];
              dontPatch = true;
              dontConfigure = true;
              dontBuild = true;
              dontFixup = true;
            };

            ameba = pkgs.stdenvNoCC.mkDerivation {
              name = "ameba";
              src = lintSrc;
              installPhase = "mkdir $out && ameba";
              nativeBuildInputs = [ pkgs.ameba ];
              dontPatch = true;
              dontConfigure = true;
              dontBuild = true;
              dontFixup = true;
            };

            specs = crystal.buildCrystalPackage {
              name = "specs";
              src = specSrc;
              buildInputs = [ pkgs.libssh2 ];
              installPhase = "mkdir $out && HOME=$TMP crystal spec --progress --threads 1";
              shardsFile = specSrc + "/shards.nix";
              doCheck = false;
              dontPatch = true;
              dontBuild = true;
              dontFixup = true;
            };
          };
        };
    in
    {
      packages = forAllSystems (system: (perSystemOutputs system).packages);
      devShells = forAllSystems (system: (perSystemOutputs system).devShells);
      checks = forAllSystems (system: (perSystemOutputs system).checks);
    };
}
