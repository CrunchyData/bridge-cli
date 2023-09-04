{
  description = "CrunchyBridge CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-crunchy.url = "github:crunchydata/nixpkgs";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, nixpkgs-crunchy, flake-utils, nix-filter }:
    let
      systems = builtins.map (a: a.system) (builtins.catAttrs "crystal" (builtins.attrValues nixpkgs-crunchy.outputs.packages));
      filterSrc = files: (nix-filter.lib { root = ./.; include = [ "src" "spec" ] ++ files; });
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crunchy = nixpkgs-crunchy.packages.${system};

        crystal = crunchy.crystal.override { extraBuildInputs = [ pkgs.libssh2 ]; };
        crystalStatic = crunchy.crystalStatic.override { extraBuildInputs = [ pkgs.pkgsStatic.libssh2 ]; };

        check = pkgs.writeScriptBin "check" "nix build .#check --keep-going --print-build-logs";
        shardFiles = [ "shard.lock" "shards.nix" "shard.yml" ];
        src = filterSrc (shardFiles ++ [ "Readme" "Changelog" ]);
        specSrc = filterSrc shardFiles;
        lintSrc = filterSrc [ ".ameba.yml" ];

        darwinBuildInputs = [
          pkgs.darwin.apple_sdk.frameworks.Foundation
          pkgs.darwin.apple_sdk.frameworks.Security
        ];
      in
      rec {
        packages.default = crystal.mkPkg {
          inherit self src;
          doCheck = false;
        };

        packages.static = crystalStatic.mkPkg {
          inherit src self;
          doCheck = false;
        };

        packages.check = pkgs.linkFarmFromDrvs "cb-all-checks" (builtins.attrValues checks);

        devShells.default = pkgs.mkShell {
          buildInputs = with crunchy; [ crystal2nix ameba ]
            ++ [ crystal check ]
            ++ [ pkgs.pcre2 pkgs.pcre pkgs.libyaml ]
            ++ pkgs.lib.optionals pkgs.stdenv.isDarwin darwinBuildInputs;
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
            nativeBuildInputs = [ crunchy.ameba ];
            dontPatch = true;
            dontConfigure = true;
            dontBuild = true;
            dontFixup = true;
          };

          specs = crystal.buildCrystalPackage {
            name = "specs";
            src = specSrc;
            HOME = "/tmp"; # needed just for cb, not in general
            installPhase = "mkdir $out && crystal spec --progress";
            shardsFile = specSrc + "/shards.nix";
            doCheck = false;
            dontPatch = true;
            dontBuild = true;
            dontFixup = true;
          };
        };
      }
    );
}
