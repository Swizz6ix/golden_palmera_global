#!/usr/bin/env bash

set -Eeuo pipefail


if [[ $# -ne 1 ]]; then
    echo "Usage: ./health-check.sh <health_url>"
    exit 1
fi


URL="$1"


echo "Checking application health..."


for i in {1..10}; do

    if curl \
        --fail \
        --silent \
        --show-error \
        "$URL" >/dev/null; then

        echo "Health check passed."
        exit 0
    fi

    echo "Application not ready ($i/10)."
    sleep 5

done


echo "Health check failed."

exit 1