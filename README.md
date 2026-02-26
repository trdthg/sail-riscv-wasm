# sail-riscv-wasm

Top-level product repository for the web-based Sail RISC-V runtime.

- `sail-riscv/` is a git submodule (tracked from `trdthg/sail-riscv:sail-riscv-wasm`).
- `dependencies/` contains top-level toolchain/data submodules (`gmp-wasm`, `binutils-wasm`, `riscv-unified-db`).
- `web/` is the deployable frontend app (GitHub Pages target).
- `src/` stores top-level source files injected into the submodule before build.

## Repository layout

- `sail-riscv/`: upstream model/build dependency (submodule)
- `dependencies/`: wasm/tooling/data dependencies (submodules)
- `web/`: frontend app, workers, tests, build output
- `scripts/`: top-level orchestration scripts
- `src/`: source files synced into submodule
- `.github/workflows/gh-pages.yml`: top-level CI/CD entry

## Bootstrap

```bash
./scripts/bootstrap-submodules.sh
```

## Sync top-level sources into submodule

```bash
./scripts/sync-sail-src.sh
```

Current synced source set includes:

- `src/riscv_debug.cpp` (copied to `sail-riscv/c_emulator/riscv_debug.cpp`)

## Build (all-in-one)

```bash
./build.sh
```

This runs: bootstrap → source sync → gmp wasm → sail wasm → binutils wasm.

## Build step-by-step

```bash
./scripts/build-gmp-wasm.sh
./scripts/build-sail-wasm.sh
./scripts/build-binutils-wasm.sh
```

`build-sail-wasm.sh` supports two modes:

- `SAIL_WASM_BUILD_MODE=superbuild` (default): uses top-level `CMakeLists.txt` wrapper target over the `sail-riscv` submodule
- `SAIL_WASM_BUILD_MODE=legacy`: uses `sail-riscv/wasm/docker-run.sh`

`build-binutils-wasm.sh` defaults to RISC-V-only + CJS outputs:

- `GAS_TARGETS=riscv64-linux-gnu`
- `GAS_BUILD_TYPES=cjs`
- `BINUTILS_BUILD_TYPES=cjs`

## Top-level CMake wrapper

You can configure the superbuild directly:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target sail_riscv_wasm_debug -j
```

With Emscripten, use `sync_web_wasm_assets` to copy outputs into `web/public`.

## Web development

```bash
pnpm -C web install
pnpm -C web dev
```

## Web checks

```bash
pnpm -C web lint
pnpm -C web typecheck
pnpm -C web test:unit
pnpm -C web test:ui
REQUIRE_BINUTILS_ASSETS=1 pnpm -C web build
```
