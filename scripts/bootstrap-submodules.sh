#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep bootstrap shallow and deterministic for CI/runtime use.
# We need sail-riscv + top-level dependencies/, but not deep optional nested
# submodules under riscv-unified-db (e.g. llvm-project).
git -C "${repo_root}" submodule sync
git -C "${repo_root}" submodule update --init \
  sail-riscv \
  dependencies/gmp-wasm \
  dependencies/binutils-wasm \
  dependencies/riscv-unified-db
