#!/usr/bin/env bash
set -euo pipefail

db="chess.db"
dbBranch="db"
user="jamesmstone"

# pgn-to-sqlite only ever INSERTs, so reusing a database would add a duplicate
# row per game on every run.
build() {
  rm -f "$db"
  pgn-to-sqlite -u "$user" -o "$db" fetch lichess
}

commitDB() {
  local tempDB
  tempDB="$(mktemp)"
  git config user.name "Automated"
  git config user.email "actions@jamesst.one"
  git branch -D "$dbBranch" || true
  git checkout --orphan "$dbBranch"
  mv "$db" "$tempDB"
  git rm -rqf .
  mv "$tempDB" "$db"
  git add -f "$db"
  git commit -m "push db"
  git push origin "HEAD:$dbBranch" -f
}

case "${1:-build}" in
build) build ;;
commit-db) commitDB ;;
*)
  echo "usage: $0 {build|commit-db}" >&2
  exit 2
  ;;
esac
