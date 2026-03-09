#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(cat "${ROOT_DIR}/VERSION")"

IMAGE_NAME="${IMAGE_NAME:-opentopodata:${VERSION}}"
CONTAINER_NAME="${CONTAINER_NAME:-opentopodata-altitude}"

HOST_PORT="${HOST_PORT:-8090}"
CONTAINER_PORT=5000

DATA_DIR="${ROOT_DIR}/data"
DATASET_NAME="copernicus_30m"
DATASET_DIR="${DATA_DIR}/${DATASET_NAME}"

# ----------------------------
# Check dataset
# ----------------------------
if [ ! -d "${DATASET_DIR}" ]; then
    echo "Error: dataset folder not found: ${DATASET_DIR}"
    echo "Put dataset inside:"
    echo "${DATASET_DIR}"
    exit 1
fi

echo "[INFO] Building Docker image ${IMAGE_NAME}..."
docker build --tag "${IMAGE_NAME}" --file "${ROOT_DIR}/docker/Dockerfile" "${ROOT_DIR}"

# ----------------------------
# Remove old container
# ----------------------------
if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "[INFO] Removing existing container ${CONTAINER_NAME}..."
    docker rm -f "${CONTAINER_NAME}"
fi

# ----------------------------
# Run container
# ----------------------------
echo "[INFO] Starting container ${CONTAINER_NAME} on port ${HOST_PORT}..."

docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -v "${DATA_DIR}:/app/data:ro" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}"

echo
echo "[INFO] Altitude API ready"
echo "Test:"
echo "http://localhost:${HOST_PORT}/altitude?locations=45.4642,9.1900"