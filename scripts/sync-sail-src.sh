#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
submodule_root="${repo_root}/sail-riscv"
debug_src="${repo_root}/src/riscv_debug.cpp"
target_file="${submodule_root}/c_emulator/riscv_debug.cpp"

if [[ ! -f "${debug_src}" ]]; then
  echo "missing source file: ${debug_src}" >&2
  exit 1
fi

cp -f "${debug_src}" "${target_file}"
echo "synced: src/riscv_debug.cpp -> sail-riscv/c_emulator/riscv_debug.cpp"
