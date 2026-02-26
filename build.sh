#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${repo_root}/scripts/bootstrap-submodules.sh"
"${repo_root}/scripts/sync-sail-src.sh"
"${repo_root}/scripts/build-gmp-wasm.sh"
"${repo_root}/scripts/build-sail-wasm.sh"
"${repo_root}/scripts/build-binutils-wasm.sh"
