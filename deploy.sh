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
FALLBACK_DATA_DIR="${ROOT_DIR}/../copernicus/opentopodata/data"
FALLBACK_DATASET_DIR="${FALLBACK_DATA_DIR}/${DATASET_NAME}"

if [ ! -d "${DATASET_DIR}" ] && [ -d "${FALLBACK_DATASET_DIR}" ]; then
    DATA_DIR="${FALLBACK_DATA_DIR}"
    DATASET_DIR="${FALLBACK_DATASET_DIR}"
    echo "Using fallback data directory: ${DATA_DIR}"
fi

if [ ! -d "${DATASET_DIR}" ]; then
    echo "Error: dataset folder not found: ${DATASET_DIR}" >&2
    echo "Copy the dataset into ${ROOT_DIR}/data and run ./deploy.sh" >&2
    echo "Suggested copy command:" >&2
    echo "  sudo rsync -a ${FALLBACK_DATASET_DIR}/ ${ROOT_DIR}/data/${DATASET_NAME}/" >&2
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
