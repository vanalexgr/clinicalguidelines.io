#!/usr/bin/env bash
set -euo pipefail

# Installs the Flutter SDK for local development.
#
# By default the stable channel release is downloaded to "../.flutter" relative
# to the repository root. Override defaults with the following environment
# variables:
#   FLUTTER_VERSION     Flutter tag to checkout (optional)
#   FLUTTER_CHANNEL     Release channel to use (default: stable)
#   FLUTTER_INSTALL_DIR Destination directory for the SDK (default: ../.flutter)

CHANNEL="${FLUTTER_CHANNEL:-stable}"
VERSION="${FLUTTER_VERSION:-}"
INSTALL_DIR="${FLUTTER_INSTALL_DIR:-$PWD/../.flutter}"
TARGET_DIR="${INSTALL_DIR}/flutter"
REPO_URL="https://github.com/flutter/flutter.git"

if [[ $(uname -s) != "Linux" ]]; then
  echo "This script currently supports Linux hosts only." >&2
  exit 1
fi

if [[ -d "${TARGET_DIR}" ]]; then
  echo "Flutter already installed at ${TARGET_DIR}" >&2
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to clone Flutter." >&2
  exit 1
fi

echo "Cloning Flutter (${CHANNEL}) into ${TARGET_DIR}…"
mkdir -p "${INSTALL_DIR}"
git clone --filter=blob:none --branch "${CHANNEL}" --depth 1 \
  "${REPO_URL}" "${TARGET_DIR}"

if [[ -n "${VERSION}" ]]; then
  echo "Checking out Flutter ${VERSION}…"
  git -C "${TARGET_DIR}" fetch --depth 1 origin "refs/tags/${VERSION}:refs/tags/${VERSION}"
  git -C "${TARGET_DIR}" checkout "${VERSION}"
fi

echo "Flutter SDK available at ${TARGET_DIR}"
echo "Add ${TARGET_DIR}/bin to your PATH to use flutter commands."
