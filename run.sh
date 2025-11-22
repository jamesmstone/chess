#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
set -o pipefail
set -o errexit
set -x

pgntosqlite() {
  docker build -t pgntosqlite .
  docker run -v"$(pwd)":/wd -w/wd -u "$(id -u):$(id -g)" pgntosqlite "$@"
}

datasette() {
  local dockerDatasette="datasette"
  docker build --tag "$dockerDatasette" --pull --file datasette.Dockerfile .
  docker run \
    -v"$(pwd):/wd" \
    -e VERCEL_TOKEN="${VERCEL_TOKEN}" \
    -w /wd \
    "$dockerDatasette" \
    "$@"
}

updateDB() {
  local db="$1"
  pgntosqlite -u jamesmstone -o "$db" fetch lichess
  # pgntosqlite -u jamesmstone -o "$db" fetch chess
}

commitDB() {
  local dbBranch="db"
  local db="$1"
  local tempDB="$(mktemp)"

  git config user.name "Automated"
  git config user.email "actions@users.noreply.github.com"

  git branch -D "$dbBranch" || true
  git checkout --orphan "$dbBranch"
  mv "$db" "$tempDB"
  rm -rf *
  mv "$tempDB" "$db"
  # tar -cvzf "$db.tar.gz" "$db"
  # split -b 99M "$db.tar.gz" "$db.tar.gz.part"
  # git add "$db.tar.gz.part*"
  # git commit "$db.tar.gz.part*" -m "push db parts"
  git add "$db"
  git commit "$db" -m "push db"
  git push origin "$dbBranch" -f
}

getDB() {
  local dbBranch="db"
  local db="$1"
  git fetch origin "$dbBranch"
  git ls-tree -r --name-only "origin/$dbBranch" |
    sort |
    xargs -I % -n1 git show "origin/$dbBranch:%" |
    tar -zxf - || return 0
}

publishDB() {
  local db=$1
  local app=$2
  datasette \
    publish vercel \
    "$db" \
    "--project=$app" \
    --generate-vercel-json > vercel.json
  sed -i 's/@vercel\/python@3\.0\.7/@vercel\/python@4.5.1/g' vercel.json
  datasette \
    publish vercel \
    "$db" \
    --token $VERCEL_TOKEN \
    "--project=$app" \
    --vercel-json=vercel.json \
    --setting sql_time_limit_ms 3500 \
    --install=datasette-vega \
    --install=datasette-cluster-map
}

getDB "chess.db" || true
updateDB "chess.db"
publishDB "chess.db" "jamesmstone-chess"
commitDB "chess.db"
