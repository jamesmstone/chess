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

      nixosModules.scraper = import ./nix/scraper-module.nix { inherit (inputs) self; };

      checks = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          pgn-to-sqlite = inputs.self.packages.${system}.pgn-to-sqlite;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          # The real unit with the lichess CLI stubbed: the database must land
          # at `publish`, and an empty scrape must leave the previous one alone.
          scraper = pkgs.testers.runNixOSTest {
            name = "chess-scraper";

            nodes.machine =
              { pkgs, ... }:
              {
                imports = [ inputs.self.nixosModules.scraper ];
                environment.systemPackages = [ pkgs.sqlite ];
                services.chess-scraper = {
                  enable = true;
                  user = "root";
                  lichessUser = "someone";
                  publish = "/srv/site/chess.db";
                  # args: -u <user> -o <db> fetch lichess
                  tool = pkgs.writeShellScriptBin "pgn-to-sqlite" ''
                    sqlite3 "$4" 'create table games(opening text)'
                    [ -e /srv/empty ] || sqlite3 "$4" "insert into games values ('Catalan by '||'$2')"
                  '';
                };
                systemd.tmpfiles.rules = [ "d /srv/site 0755 root root -" ];
                systemd.timers.chess-scraper.wantedBy = pkgs.lib.mkForce [ ];
              };

            testScript = ''
              machine.wait_for_unit("multi-user.target")
              machine.succeed("systemctl start chess-scraper.service")
              assert machine.succeed("sqlite3 /srv/site/chess.db 'select opening from games'").strip() == "Catalan by someone"

              machine.succeed("touch /srv/empty")
              machine.fail("systemctl start chess-scraper.service")
              assert machine.succeed("sqlite3 /srv/site/chess.db 'select count(*) from games'").strip() == "1"
            '';
          };
        }
      );

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
