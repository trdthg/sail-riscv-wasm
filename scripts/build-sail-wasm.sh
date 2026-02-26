#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
submodule_root="${repo_root}/sail-riscv"
submodule_web_public="${submodule_root}/wasm/web/public"
out_public="${repo_root}/web/public"
gmp_dist_default="${repo_root}/dependencies/gmp-wasm/binding/gmp/dist"
build_mode="${SAIL_WASM_BUILD_MODE:-superbuild}"

if [[ "${build_mode}" == "legacy" ]]; then
  "${submodule_root}/wasm/docker-run.sh"
else
  SAIL_VERSION="${SAIL_VERSION:-0.20.1}"
  SAIL_URL="${SAIL_URL:-https://github.com/rems-project/sail/releases/download/${SAIL_VERSION}/sail-Linux-x86_64.tar.gz}"
  gmp_dist_host="${GMP_WASM_DIST:-${gmp_dist_default}}"
  [[ -f "${gmp_dist_host}/lib/libgmp.a" ]] || { echo "error: GMP_WASM_DIST not found at ${gmp_dist_host}" >&2; exit 1; }

  sail_dir="${submodule_root}/wasm/sail"
  if [[ ! -x "${sail_dir}/bin/sail" ]]; then
    echo "Sail not found; downloading ${SAIL_VERSION}..." >&2
    archive="/tmp/sail.tar.gz"
    curl -L "${SAIL_URL}" -o "${archive}"
    tar -xzf "${archive}" -C "${submodule_root}/wasm"
  fi

  image="${EMSDK_IMAGE:-emscripten/emsdk:latest}"
  gmp_dist_container="/work${gmp_dist_host#${repo_root}}"

  docker run --rm -i \
    -u "$(id -u):$(id -g)" \
    -v "${repo_root}:/work" \
    -w /work \
    -e GMP_WASM_DIST="${gmp_dist_container}" \
    -v "${sail_dir}:/sail" \
    -e SAIL_BIN="/sail/bin/sail" \
    "${image}" \
    bash -lc '
      set -euo pipefail
      if [ -f /emsdk/emsdk_env.sh ]; then source /emsdk/emsdk_env.sh >/dev/null 2>&1; fi
      if [ -d /sail/bin ]; then export PATH="/sail/bin:$PATH"; fi

      build_dir="/work/build-emscripten-wrapper"
      link_flags="-s MODULARIZE=1 -s EXPORT_NAME=createSailModule -s INVOKE_RUN=0 -s EXIT_RUNTIME=0 -s ALLOW_MEMORY_GROWTH=1 -s EXPORTED_RUNTIME_METHODS=callMain,FS,HEAPU8 -s DISABLE_EXCEPTION_CATCHING=0 -s WASM_BIGINT=1 -s EMULATE_FUNCTION_POINTER_CASTS=1 -s ASSERTIONS=2 -s STACK_SIZE=4194304"

      emcmake cmake -S /work -B "${build_dir}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DGMP_WASM_DIST="${GMP_WASM_DIST}" \
        -DCMAKE_EXE_LINKER_FLAGS="${link_flags}" \
        -DCMAKE_CROSSCOMPILING_EMULATOR="/bin/true"

      cmake --build "${build_dir}" --target sync_web_wasm_assets -j

      mkdir -p /work/web/public/config
      if compgen -G "${build_dir}/sail-riscv-build/config/*.json" > /dev/null; then
        cp -f "${build_dir}/sail-riscv-build/config/"*.json /work/web/public/config/
      fi
    '
fi

mkdir -p "${out_public}/wasm" "${out_public}/config"

if [[ -f "${submodule_web_public}/sail_riscv_debug.js" && -f "${submodule_web_public}/sail_riscv_debug.wasm" ]]; then
  cp -f "${submodule_web_public}/sail_riscv_debug.js" "${out_public}/sail_riscv_debug.js"
  cp -f "${submodule_web_public}/sail_riscv_debug.wasm" "${out_public}/sail_riscv_debug.wasm"
  cp -f "${submodule_web_public}/sail_riscv_debug.js" "${out_public}/wasm/sail_riscv_debug.js"
  cp -f "${submodule_web_public}/sail_riscv_debug.wasm" "${out_public}/wasm/sail_riscv_debug.wasm"
fi

if compgen -G "${submodule_web_public}/config/*.json" > /dev/null; then
  cp -f "${submodule_web_public}/config/"*.json "${out_public}/config/"
fi

echo "synced sail wasm assets to ${out_public}"
