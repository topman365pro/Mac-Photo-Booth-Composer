#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"

cmake -S . -B "${BUILD_DIR}" -G Ninja
cmake --build "${BUILD_DIR}"
cmake --install "${BUILD_DIR}" --prefix "${BUILD_DIR}/install"
echo "macOS bundle installed under ${BUILD_DIR}/install"
