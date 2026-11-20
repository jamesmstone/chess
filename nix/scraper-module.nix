{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.chess-scraper;
  q = lib.escapeShellArg;

  scrape = pkgs.writeShellScript "chess-scrape" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.sqlite ]}
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    # pgn-to-sqlite only INSERTs, so it needs a fresh file or games duplicate.
    ${lib.getExe cfg.tool} -u ${q cfg.lichessUser} -o "$tmp/chess.db" fetch lichess
    # An empty scrape must not replace the last good database.
    [ "$(sqlite3 "$tmp/chess.db" 'select count(*) from games')" -gt 0 ]
    # Renamed into place: readers may hold the old file open, and writing in
    # place would show them a torn one.
    install -Dm644 "$tmp/chess.db" ${q "${cfg.publish}.new"}
    mv -f ${q "${cfg.publish}.new"} ${q cfg.publish}
  '';
in
{
  options.services.chess-scraper = {
    enable = lib.mkEnableOption "the lichess game scraper";

    tool = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.pgn-to-sqlite;
      defaultText = lib.literalExpression "chess.packages.\${system}.pgn-to-sqlite";
      description = "The pgn-to-sqlite CLI.";
    };

    lichessUser = lib.mkOption {
      type = lib.types.str;
      default = "jamesmstone";
      description = "Lichess account to fetch games for.";
    };

    publish = lib.mkOption {
      type = lib.types.str;
      example = "/var/lib/dbs/chess/chess.db";
      description = "Where the database is installed. Its directory must exist and be writable by `user`.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "james";
      description = "User the scrape runs as.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 04:00:00";
      description = "systemd OnCalendar expression.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.chess-scraper = {
      description = "Scrape lichess games into chess.db";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        ExecStart = scrape;
        TimeoutStartSec = "30min";
        Nice = 19;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    systemd.timers.chess-scraper = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true;
        Unit = "chess-scraper.service";
      };
    };
  };
}
