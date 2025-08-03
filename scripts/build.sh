#!/usr/bin/env bash
# build, test, and clean script for NetLedger
# Example usage:
#
# configure & build
#./scripts/build.sh
#
# run tests
#./scripts/build.sh test
#
# clean everything
#./scripts/build.sh clean

set -euo pipefail

BUILD_DIR="build"

print_usage() {
  cat <<EOF
Usage: $0 [deps|build|test|clean]

  deps    Check for & install system dependencies
  build   Configure & build (default if no command given)
  test    Build (if needed) and run unit tests
  clean   Remove the build directory
EOF
}

# ------------------------------------------------------------
# Dependency definitions for apt
APT_DEPS=(cmake build-essential libpcap-dev nlohmann-json3-dev libgtest-dev)

install_deps() {
  echo "Updating apt repositories..."
  sudo apt-get update
  echo "Installing: ${APT_DEPS[*]}"
  sudo apt-get install -y "${APT_DEPS[@]}"
  # Build & install gtest library
  echo "Building and installing libgtest..."
  cd /usr/src/gtest
  sudo cmake .
  sudo make
  sudo cp lib/*.a /usr/lib/
  cd -
}

check_deps() {
  MISSING=()
  command -v cmake   &>/dev/null || MISSING+=("cmake")
  pkg-config --exists libpcap || MISSING+=("libpcap-dev")
  pkg-config --exists nlohmann_json || MISSING+=("nlohmann-json3-dev")
  pkg-config --exists gtest || MISSING+=("libgtest-dev")
  command -v g++     &>/dev/null || MISSING+=("build-essential")
  if [ "${#MISSING[@]}" -ne 0 ]; then
    echo "Missing: ${MISSING[*]}"
    return 1
  fi
  return 0
}

# ------------------------------------------------------------
case "${1:-build}" in

  deps)
    echo "==> Checking dependencies..."
    if ! check_deps; then
      echo "==> Installing missing dependencies..."
      install_deps
      echo "==> Re-checking dependencies..."
      check_deps
    else
      echo "All dependencies are already installed."
    fi
    ;;

  build)
    echo "==> Verifying dependencies..."
    if ! check_deps; then
      echo "Some dependencies are missing; run '$0 deps' to install them."
      exit 1
    fi

    mkdir -p "${BUILD_DIR}"
    pushd "${BUILD_DIR}" >/dev/null
      cmake ..
      make -j"$(nproc)"
    popd >/dev/null
    ;;

  test)
    echo "==> Verifying dependencies..."
    if ! check_deps; then
      echo "Some dependencies are missing; run '$0 deps' to install them."
      exit 1
    fi

    mkdir -p "${BUILD_DIR}"
    pushd "${BUILD_DIR}" >/dev/null
      cmake ..
      make -j"$(nproc)" netledger_test
      ctest --output-on-failure
    popd >/dev/null
    ;;

  clean)
    rm -rf "${BUILD_DIR}"
    ;;

  *)
    print_usage
    exit 1
    ;;
esac
