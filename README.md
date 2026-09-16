# bombsquad-dockerized

A Docker image that fetches and runs the official [BombSquad](https://ballistica.net)
(Ballistica) headless dedicated server, configured entirely through environment
variables or a mounted `config.toml`.

This project is unaffiliated with Ballistica/Eric Froemling. It doesn't vendor
any game binaries or assets — the Dockerfile downloads the official server
tarball from `files.ballistica.net` at build time.

## Quick start

```bash
docker run -d \
  --name bombsquad \
  -p 43210:43210/udp \
  -v bombsquad-data:/data \
  -e PARTY_NAME="My Server" \
  -e SESSION_TYPE=ffa \
  -e FFA_SERIES_LENGTH=24 \
  ghcr.io/abexamir/bombsquad-dockerized:latest
```

Connect from BombSquad via direct IP connect on port `43210` (UDP).

The published image is built from BombSquad server version `1.7.43`.

## Building a different server version

BombSquad clients reject servers running a build that's too far ahead (or
sometimes behind) their own protocol generation, with messages like "host is
running a newer version of this game." If players can't join with the
published image, you may need a different official build than the one it
ships — build the image yourself with `--build-arg BOMBSQUAD_VERSION=x.y.z`
(official builds are listed at
`https://files.ballistica.net/bombsquad/builds/old/`):

```bash
git clone https://github.com/abexamir/bombsquad-dockerized
cd bombsquad-dockerized
docker build --build-arg BOMBSQUAD_VERSION=1.7.53 -t bombsquad-dockerized .
```

Then swap `ghcr.io/abexamir/bombsquad-dockerized:latest` for `bombsquad-dockerized`
in the `docker run` command above.

## Configuration

On first run, if `/data/config.toml` doesn't exist, one is generated from
these environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `PARTY_NAME` | `BombSquad Dockerized Server` | Name shown in the public party list |
| `PARTY_IS_PUBLIC` | `false` | List the server publicly |
| `AUTHENTICATE_CLIENTS` | `true` | Screen clients via the master server |
| `ADMINS` | *(empty)* | Comma-separated list of admin account IDs (`pb-xxxx,pb-yyyy`) |
| `ENABLE_DEFAULT_KICK_VOTING` | `true` | Enable the built-in kick-vote system |
| `PORT` | `43210` | UDP port to host on |
| `MAX_PARTY_SIZE` | `9` | Max devices in the party (includes the server itself) |
| `SESSION_MAX_PLAYERS_OVERRIDE` | `8` | Max players in the session |
| `SESSION_TYPE` | `ffa` | `ffa`, `teams`, or `coop` |
| `PLAYLIST_CODE` | *(unset)* | Numeric shared-playlist code, if using a custom playlist |
| `PLAYLIST_SHUFFLE` | `true` | Shuffle playlist order |
| `AUTO_BALANCE_TEAMS` | `true` | Keep team sizes even (teams mode) |
| `TEAMS_SERIES_LENGTH` | `7` | Best-of-N series length (teams mode) |
| `FFA_SERIES_LENGTH` | `24` | Points to win (FFA mode) |
| `SHOW_TUTORIAL` | `false` | Show the tutorial at game start |
| `ENABLE_QUEUE` | `true` | Enable the join queue |
| `PLAYER_REJOIN_COOLDOWN` | `10.0` | Seconds before a leaving player can rejoin |

For anything not covered above, mount your own file at `/data/config.toml`
(env vars are only used when that file doesn't already exist) — see the
[official config reference](https://ballistica.net) for the full option list.

### Persistent data

`/data` holds both `config.toml` and the engine's `ba_root` directory (player
profiles, ban lists, stats cache, etc). Mount a volume there to persist state
across container restarts:

```bash
-v bombsquad-data:/data
```

### Running behind a restrictive network

If the host can't reach BombSquad's master servers directly (some hosting
providers/networks transparently block or intercept it), player names and
characters may show up as randomized defaults instead of their real profiles.
Point the container at an HTTP/SOCKS proxy with the standard proxy
environment variables — Python's `urllib` (used by the server) picks these up
automatically:

```bash
-e HTTP_PROXY=http://host.docker.internal:9010 \
-e HTTPS_PROXY=http://host.docker.internal:9010
```

## License

The Dockerfile, entrypoint script, and CI workflow in this repo are MIT
licensed (see [LICENSE](./LICENSE)). The BombSquad server binary itself is
downloaded at build time and is copyright its own author under its own
license.
