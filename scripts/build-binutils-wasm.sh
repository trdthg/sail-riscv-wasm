#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
binutils_root="${repo_root}/dependencies/binutils-wasm"
binutils_build_script="${binutils_root}/packages/binutils/build/build.sh"

pnpm -C "${binutils_root}" install

if grep -q '"--disable-ld"' "${binutils_build_script}"; then
  sed -i '/"--disable-ld"/d' "${binutils_build_script}"
fi
if ! grep -q '"ld/ld-new"' "${binutils_build_script}"; then
  sed -i '/"binutils\/elfedit"/a\    "ld/ld-new"' "${binutils_build_script}"
fi
if grep -q '"--enable-targets=all"' "${binutils_build_script}"; then
  sed -i 's/"--enable-targets=all"/"--enable-targets=riscv64-unknown-elf"/' "${binutils_build_script}"
fi

export BINUTILS_REPO_URL="${BINUTILS_REPO_URL:-https://sourceware.org/git/binutils-gdb.git}"
export GAS_TARGETS="${GAS_TARGETS:-riscv64-linux-gnu}"
export GAS_BUILD_TYPES="${GAS_BUILD_TYPES:-cjs}"
export BINUTILS_BUILD_TYPES="${BINUTILS_BUILD_TYPES:-cjs}"

pnpm -C "${binutils_root}/packages/gas" run build:wasm "--build-arg=TARGET=${GAS_TARGETS}"
pnpm -C "${binutils_root}/packages/binutils" run build:wasm

test -f "${binutils_root}/packages/gas/build/dist/cjs/riscv64-linux-gnu.js"
test -f "${binutils_root}/packages/binutils/build/dist/cjs/ld.js"
test -f "${binutils_root}/packages/binutils/build/dist/cjs/readelf.js"
test -f "${binutils_root}/packages/binutils/build/dist/cjs/objdump.js"

echo "binutils wasm assets are ready"
