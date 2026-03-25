#!/bin/bash
set -euo pipefail

# Inject Infisical secrets into the environment
if [ -n "${WORKMUX_INFISICAL_TOKEN:-}" ]; then
    export INFISICAL_TOKEN="$WORKMUX_INFISICAL_TOKEN"
    eval "$(infisical export \
        --domain=https://infisical.studyflash.ch \
        --projectId=0fd370f1-e95b-42e3-8b8d-44f9e6d3b03f \
        --env=dev \
        --format=dotenv-export)"
    unset INFISICAL_TOKEN
fi

exec "$@"
