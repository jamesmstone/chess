{
  description = "Chess game scraper — chess.jamesst.one";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs:
    let
      eachSystem = inputs.nixpkgs.lib.genAttrs (import inputs.systems);
      pkgsFor = eachSystem (system: import inputs.nixpkgs { inherit system; });
    in
    {
      packages = eachSystem (system: rec {
        pgn-to-sqlite = pkgsFor.${system}.callPackage ./nix/pgn-to-sqlite.nix { };
        default = pgn-to-sqlite;
      });

      checks = eachSystem (system: {
        pgn-to-sqlite = inputs.self.packages.${system}.pgn-to-sqlite;
      });

      devShells = eachSystem (system: {
        default = pkgsFor.${system}.mkShell {
          packages = [
            inputs.self.packages.${system}.pgn-to-sqlite
          ]
          ++ (with pkgsFor.${system}; [
            git
            sqlite-utils
          ]);
        };
      });
    };
}
