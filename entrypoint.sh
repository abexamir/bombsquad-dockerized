#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/data"
CONFIG_PATH="${DATA_DIR}/config.toml"
ROOT_PATH="${DATA_DIR}/ba_root"

mkdir -p "${ROOT_PATH}"

if [ ! -f "${CONFIG_PATH}" ]; then
    echo "No ${CONFIG_PATH} found, generating one from environment variables..."

    admins_toml="[]"
    if [ -n "${ADMINS:-}" ]; then
        admins_toml=$(python3.13 -c '
import json, os
ids = [x.strip() for x in os.environ["ADMINS"].split(",") if x.strip()]
print(json.dumps(ids))
')
    fi

    playlist_line="#playlist_code = 12345"
    if [ -n "${PLAYLIST_CODE:-}" ]; then
        playlist_line="playlist_code = ${PLAYLIST_CODE}"
    fi

    cat > "${CONFIG_PATH}" <<EOF
# Auto-generated from environment variables by entrypoint.sh.
# Delete the env vars and edit/mount this file directly for full control -
# see https://ballistica.net for the full list of available options.

party_name = "${PARTY_NAME:-BombSquad Dockerized Server}"
party_is_public = ${PARTY_IS_PUBLIC:-false}
authenticate_clients = ${AUTHENTICATE_CLIENTS:-true}
admins = ${admins_toml}
enable_default_kick_voting = ${ENABLE_DEFAULT_KICK_VOTING:-true}
port = ${PORT:-43210}
max_party_size = ${MAX_PARTY_SIZE:-9}
session_max_players_override = ${SESSION_MAX_PLAYERS_OVERRIDE:-8}
session_type = "${SESSION_TYPE:-ffa}"
${playlist_line}
playlist_shuffle = ${PLAYLIST_SHUFFLE:-true}
auto_balance_teams = ${AUTO_BALANCE_TEAMS:-true}
teams_series_length = ${TEAMS_SERIES_LENGTH:-7}
ffa_series_length = ${FFA_SERIES_LENGTH:-24}
show_tutorial = ${SHOW_TUTORIAL:-false}
enable_queue = ${ENABLE_QUEUE:-true}
player_rejoin_cooldown = ${PLAYER_REJOIN_COOLDOWN:-10.0}
EOF
else
    echo "Using existing ${CONFIG_PATH}"
fi

exec /app/bombsquad_server --config "${CONFIG_PATH}" --root "${ROOT_PATH}" "$@"
