# A Chess datasette instance of my games

https://chess.jamesst.one

Enables quick analysis and charting eg [my elo over time](https://chess.jamesst.one/chess?sql=select%0D%0A++id%2C%0D%0A++event%2C%0D%0A++site%2C%0D%0A++date%2C%0D%0A++round%2C%0D%0A++white%2C%0D%0A++black%2C%0D%0A++result%2C%0D%0A++eco%2C%0D%0A++white_elo%2C%0D%0A++black_elo%2C%0D%0A++variant%2C%0D%0A++time_control%2C%0D%0A++termination%2C%0D%0A++moves%2C%0D%0A++case%0D%0A++++when+black+%3D+%27jamesmstone%27+then+black_elo%0D%0A++++else+white_elo%0D%0A++end+as+james_elo%0D%0Afrom%0D%0A++games%0D%0Aorder+by%0D%0A++date%0D%0Alimit%0D%0A++101#g.mark=line&g.x_column=date&g.x_type=temporal&g.y_column=james_elo&g.y_type=quantitative)

```bash
nix develop        # pgn-to-sqlite, git, sqlite-utils
./run.sh build     # lichess -> chess.db
./run.sh commit-db # force-push chess.db to the `db` branch
```

`chess.db` is not committed to `main`; the built database lives on the orphan
[`db`](../../src/branch/db) branch, and the scrape also installs it to
`/var/lib/datasette-sites/chess/chess.db` on hermanii, where Datasette serves
it.

## The lichess export endpoint is currently 404

`GET https://lichess.org/api/games/user/{username}` — the only way to list a
player's games, and what `pgn-to-sqlite fetch lichess` calls — answers 404 for
every username, from every IP, while `/api/user/{username}` still answers 200.
See [lichess-org/api#667](https://github.com/lichess-org/api/issues/667). Until
that is resolved the scrape fails and the `db` branch holds the last good
database.
