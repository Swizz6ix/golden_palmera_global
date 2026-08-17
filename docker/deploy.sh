#!/usr/bin/env bash

set -Eeuo pipefail


# ----------------------------------------
# Logging
# ----------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}


# ----------------------------------------
# Arguments
# ----------------------------------------

if [[ $# -ne 4 ]]; then
    echo "Usage:"
    echo "./deploy.sh <image_name> <image_tag> <health_url> <base_url>"
    exit 1
fi

IMAGE_NAME="$1"
IMAGE_TAG="$2"
HEALTH_URL="$3"
BASE_URL="$4"


# ----------------------------------------
# Configuration
# ----------------------------------------

COMPOSE_FILE="docker-compose.yml"
CONTAINER_NAME="golden-palmera-global"
ROLLBACK_FILE=".previous_image"


# ----------------------------------------
# Save current image
# ----------------------------------------

log "Checking current deployment..."

CURRENT_IMAGE=$(
    docker inspect "$CONTAINER_NAME" \
        --format='{{.Config.Image}}' \
        2>/dev/null || true
)

if [[ -n "$CURRENT_IMAGE" ]]; then
    echo "$CURRENT_IMAGE" > "$ROLLBACK_FILE"
    log "Current image: $CURRENT_IMAGE"
else
    log "No existing deployment found."
fi


# ----------------------------------------
# Configure new image
# ----------------------------------------

export IMAGE_NAME
export IMAGE_TAG

log "Deploying:"
log "Image: ${IMAGE_NAME}:${IMAGE_TAG}"


# ----------------------------------------
# Pull image
# ----------------------------------------

log "Pulling Docker image..."

docker compose \
    -f "$COMPOSE_FILE" \
    pull app


# ----------------------------------------
# Start application
# ----------------------------------------

log "Starting application..."

docker compose \
    -f "$COMPOSE_FILE" \
    up -d \
    --remove-orphans


# ----------------------------------------
# Wait for health
# ----------------------------------------

log "Waiting for application health..."

HEALTHY=false

for i in {1..30}; do

    if curl \
        --fail \
        --silent \
        --show-error \
        "$HEALTH_URL" >/dev/null; then

        HEALTHY=true
        break
    fi

    log "Application not ready yet ($i/30)..."
    sleep 5

done


# ----------------------------------------
# Health failure
# ----------------------------------------

if [[ "$HEALTHY" != true ]]; then
    log "Health check failed."

    if [[ -x "./rollback.sh" ]]; then
        ./rollback.sh
    fi

    exit 1
fi


log "Health check passed."


# ----------------------------------------
# Additional health checks
# ----------------------------------------

if [[ -x "./health-check.sh" ]]; then
    log "Running additional health checks..."
    ./health-check.sh "$HEALTH_URL"
fi


# ----------------------------------------
# Smoke tests
# ----------------------------------------

if [[ -x "./smoke-test.sh" ]]; then
    log "Running smoke tests..."
    ./smoke-test.sh "$BASE_URL"
fi


# ----------------------------------------
# Cleanup
# ----------------------------------------

log "Cleaning unused Docker images..."

docker image prune -f >/dev/null || true


# ----------------------------------------
# Deployment complete
# ----------------------------------------

rm -f "$ROLLBACK_FILE"

log "Deployment completed successfully."

docker compose \
    -f "$COMPOSE_FILE" \
    ps