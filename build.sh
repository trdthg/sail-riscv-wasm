
docker build -f Dockerfile . --tag=sail-riscv-wasm-builder:latest

container_id=$(docker create sail-riscv-wasm-builder)
docker cp "$container_id:/src/sail-riscv/c_emulator/riscv_sim_RV64.wasm" "."
docker rm "$container_id"