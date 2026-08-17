#!/usr/bin/env bash

set -Eeuo pipefail


if [[ $# -ne 1 ]]; then
    echo "Usage: ./smoke-test.sh <base_url>"
    exit 1
fi


BASE_URL="$1"


echo "Running smoke tests..."


echo "Testing homepage..."

curl \
    --fail \
    --silent \
    --show-error \
    "$BASE_URL/" >/dev/null


echo "Testing health endpoint..."

curl \
    --fail \
    --silent \
    --show-error \
    "$BASE_URL/health" >/dev/null


echo "Smoke tests passed."