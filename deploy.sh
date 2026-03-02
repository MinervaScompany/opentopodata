#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "${ROOT_DIR}/VERSION")"

IMAGE_NAME="${IMAGE_NAME:-opentopodata:${VERSION}}"
CONTAINER_NAME="${CONTAINER_NAME:-opentopodata-altitude}"
HOST_PORT="${HOST_PORT:-8090}"
CONTAINER_PORT=5000
DATA_DIR="${DATA_DIR:-${ROOT_DIR}/data}"
DATASET_NAME="${DATASET_NAME:-copernicus_30m}"
DATASET_DIR="${DATA_DIR}/${DATASET_NAME}"

if [ ! -d "${DATASET_DIR}" ]; then
    echo "Error: dataset folder not found: ${DATASET_DIR}" >&2
    echo "Set DATA_DIR to the parent folder that contains '${DATASET_NAME}'." >&2
    echo "Example: DATA_DIR=/mnt/dem ./deploy.sh" >&2
    exit 1
fi

echo "Building image ${IMAGE_NAME}..."
docker build --tag "${IMAGE_NAME}" --file "${ROOT_DIR}/docker/Dockerfile" "${ROOT_DIR}"

if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "Removing existing container ${CONTAINER_NAME}..."
    docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

echo "Starting container ${CONTAINER_NAME} on port ${HOST_PORT}..."
docker run -d --rm \
    --name "${CONTAINER_NAME}" \
    --volume "${DATA_DIR}:/app/data:ro" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}" >/dev/null

echo "Done."
echo "Test endpoint:"
echo "  http://localhost:${HOST_PORT}/altitude?locations=45.4642,9.1900"
