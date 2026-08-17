#!/usr/bin/env bash

set -Eeuo pipefail


log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}


ROLLBACK_FILE=".previous_image"
COMPOSE_FILE="docker-compose.yml"


if [[ ! -f "$ROLLBACK_FILE" ]]; then
    log "No previous image found."
    exit 1
fi


PREVIOUS_IMAGE=$(cat "$ROLLBACK_FILE")


if [[ -z "$PREVIOUS_IMAGE" ]]; then
    log "Previous image is empty."
    exit 1
fi


log "Rolling back to:"
log "$PREVIOUS_IMAGE"


# Split the final :tag from the image reference.
IMAGE_TAG="${PREVIOUS_IMAGE##*:}"
IMAGE_NAME="${PREVIOUS_IMAGE%:${IMAGE_TAG}}"


export IMAGE_NAME
export IMAGE_TAG


log "Pulling previous image..."

docker compose \
    -f "$COMPOSE_FILE" \
    pull app


log "Starting previous version..."

docker compose \
    -f "$COMPOSE_FILE" \
    up -d \
    --remove-orphans


log "Rollback completed."

docker compose \
    -f "$COMPOSE_FILE" \
    ps